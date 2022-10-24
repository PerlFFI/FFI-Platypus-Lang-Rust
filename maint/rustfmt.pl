use strict;
use warnings;
use Path::Tiny qw( path );

path('examples')->visit(sub {

  my($path, $state) = @_;
  return unless $path->basename =~ /\.rs$/;

  print "$path\n";
  system 'rustfmt', "$path";

}, { recurse => 1 });
