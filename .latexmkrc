#For capturing stdout and stderr
use IPC::Run 'run';

$ENV{'TEXINPUTS'}='./sty//:' . $ENV{'TEXINPUTS'}; 

# support for the glossaries package:
add_cus_dep('glo', 'gls', 0, 'makeglossaries');
add_cus_dep('acn', 'acr', 0, 'makeglossaries');
sub makeglossaries {
  system("makeglossaries \"$_[0]\"");
}

# support for the nomencl package:
add_cus_dep('nlo', 'nls', 0, 'makenlo2nls');
sub makenlo2nls {
  system("makeindex -s nomencl.ist -o \"$_[0].nls\" \"$_[0].nlo\"");
}

# from the documentation for V. 2.03 of asymptote:
sub asy {return system("asy \"$_[0]\"");}
add_cus_dep("asy","eps",0,"asy");
add_cus_dep("asy","pdf",0,"asy");
add_cus_dep("asy","tex",0,"asy");

# metapost rule from http://tex.stackexchange.com/questions/37134
add_cus_dep('mp', '1', 0, 'mpost');
sub mpost {
  my $file = $_[0];
  my ($name, $path) = fileparse($file);
  pushd($path);
  my $return = system "mpost $name";
  popd();
  return $return;
}

# Use subroutine to do preprocessing and running pdflatex
$pdflatex = 'internal mypdflatex %B %O';
$xelatex = 'internal myxelatex %B %O';
$ott_bin = '/home/joey/GitHub/ott/bin/ott';
add_cus_dep('mng', 'tex', 0, 'run_mngfilter'); 
$clean_ext = "*MNG.tex";

sub run_mngfilter {
    print "Calling Ott with arguments in $_[0].mng out $_[0].tex";
    call_ott( "$_[0].mng", "$_[0].tex");
}

sub mypdflatex {
  mylatex('pdflatex', @_);
}

sub myxelatex {
  mylatex('xelatex', @_);
}

sub call_ott {
  my $tex = shift @_; 
  my $outname = shift @_;
  system("$ott_bin", '-colour', 'false', '-i', './GTFL.ott', '-tex_filter', $tex, $outname);
}

sub gen_ott_tex {
  # system("rm",  './GTFL_defns.tex');
  system("$ott_bin", '-i', 'GTFL.ott', '-o', 'GTFL_defns.tex', '-tex_wrap', 'false', '-tex_show_meta', 'false', );
}

sub fix_synctex {
  my $base = shift @_; 
  run ["gunzip", "./$base.synctex.gz"];
  #cleanup the synctex files
  run ["sed", "-i.bak", 's/-filtered//', "$base.synctex"];
  run ["sed", "-i.bak", 's/MNG.tex/MNG.mng/', "$base.synctex"];
  run ["gzip", "$base.synctex"];

  #Fix logfile too
  run ["sed", "-i.bak", 's/-filtered//', "$base.log"];
  run ["sed", "-i.bak", 's/MNG.tex/MNG.mng/', "$base.log"];
  run ["sed", "-i.bak", 's/-filtered//', "$base.fls"];
}


sub mylatex {
  my $engine = shift @_; 
  my $base = shift @_;
  my $tex = "$base.tex";

  
 
  # Run the preprocessor
  gen_ott_tex();
  call_ott($tex,  "$base-filtered.tex");
  # Run pdflatex
  # my $return = system("$engine",  @_, "--jobname=$base", "$base-filtered.tex");
  run ["$engine",  @_, "--jobname=$base", "$base-filtered.tex"], ">", \my $mystdout, "2>", \my $mystderr;
  my $return = $?;

  $mystdout =~ s/-filtered//g ;
  $mystdout =~  s/MNG\.tex/MNG\.mng/g;
  $mystderr =~ s/-filtered//g ;
  $mystderr =~ s/MNG\.tex/MNG\.mng/g;

  print STDOUT "$mystdout";
  print STDERR "$mystderr";

  # system('rm', '-f', "$base-filtered.tex");
  fix_synctex("$base");
  return $return;
}