package mymm;

use strict;
use warnings;
use File::Which qw( which );
use ExtUtils::MakeMaker ();

sub myWriteMakefile
{
  my %args = @_;

  # if we can already find rustc and cargo
  # then we don't really need the alien
  # anymore
  if(which('rustc') && which('cargo'))
  {
    print "Rust and Cargo detected, not using Alien::Rust";
    delete $args{PREREQ_PM}->{'Alien::Rust'};
  }
  else
  {
    print "Cannot find Rust and Cargo in the PATH, will use Alien::Rust";
  }
  
  ExtUtils::MakeMaker::WriteMakefile(%args);
}

1;
