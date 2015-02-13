use strict;
use warnings;
use File::chdir;
use File::Glob qw( bsd_glob );

do {

  local $CWD = 'examples';
  
  foreach my $rsfile (bsd_glob '*.rs')
  {
    #rustc --crate-type dylib points.rs
    my @cmd = ('rustc', '--crate-type' => 'dylib', $rsfile);
    print "+ @cmd\n";
    system @cmd;
    exit 2 if $?;
  }

  foreach my $plfile (bsd_glob '*.pl')
  {
    my @cmd = ( $^X, '-Mblib', $plfile );
    print "+ @cmd\n";
    system @cmd;
    exit 2 if $?;
  }

};

