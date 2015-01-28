package My::ModuleBuild;

use strict;
use warnings;
use base qw( Module::Build::FFI );

sub ACTION_dist
{
  my($self) = @_;
  $self->dispatch('distdir');
  
  my $dist_dir = $self->dist_dir;
  $self->make_tarball($dist_dir);
  # $self->delete_filetree($dist_dir);
}

1;
