#For capturing stdout and stderr
use IPC::Run 'run';

$ENV{'TEXINPUTS'}='';

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

  system('rm', '-f', "$base-filtered.tex");
  fix_synctex("$base");
  return $return;
}