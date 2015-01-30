package Module::Build::FFI::Rust;

use strict;
use warnings;
use Config;
use File::Glob qw( bsd_glob );
use File::Which qw( which );
use base qw( Module::Build::FFI );

=head1 NAME

Module::Build::FFI::Rust - Build Perl extensions in Rust with FFI

=head1 DESCRIPTION

L<Module::Build::FFI> variant for writing Perl extensions in Rust wiht 
FFI (sans XS).

=head1 BASE CLASS

All methods, properties and actions are inherited from:

L<Module::Build::FFI>

=head1 PROPERTIES

Currently the Rust compile and link is done in one command so these are 
both provided to that one step.

=over 4

=item ffi_rust_extra_compiler_flags

Extra compiler flags to be passed to C<rustc>.

Must be a array reference.

=item ffi_rust_extra_linker_flags

Extra linker flags to be passed to C<rustc>.

Must be a array reference.

=back

=cut

__PACKAGE__->add_property( ffi_rust_extra_compiler_flags =>
  default => [],
);

__PACKAGE__->add_property( ffi_rust_extra_linker_flags =>
  default => [],
);

=head1 BASE CLASS

=over

=item L<Module::Build::FFI>

=back

=head1 METHODS

=head2 ffi_have_compiler

 my $has_compiler = $mb->ffi_have_compiler;

Returns true if a rust compiler (rustc) is available.

=cut

sub ffi_have_compiler
{
  my($self) = @_;
  
  my $rustc = which('rustc');
  
  return !!$rustc;
}

=head2 ffi_build_dynamic_lib

 my $dll_path = $mb->ffi_build_dynamic_lib($src_dir, $name, $target_dir);
 my $dll_path = $mb->ffi_build_dynamic_lib($src_dir, $name);

Compiles the Rust source in the C<$src_dir> and link it into a dynamic library
with base name of C<$name.$Config{dlexe}>.  If C<$target_dir> is specified
then the dynamic library will be delivered into that directory.

=cut

sub ffi_build_dynamic_lib
{
  my($self, $src_dir, $name, $target_dir) = @_;
  
  $target_dir = $src_dir unless defined $target_dir;
  my @sources = bsd_glob("$src_dir/*.rs");
  
  return unless @sources;
  
  if(@sources != 1)
  {
    print STDERR "Only one Rust source file at a time please.\n";
    print STDERR "You appear to have more than one in $src_dir.\n";
    exit 2;
  }

  my $rustc = which('rustc');
  
  my $dll = File::Spec->catfile($target_dir, "$name.$Config{dlext}");
  
  my @cmd = (
    $rustc,
    @{ $self->ffi_rust_extra_compiler_flags },
    @{ $self->ffi_rust_extra_linker_flags },
    '--crate-type' => 'dylib',
    @sources,
    '-o', => $dll,
  );
  
  print "@cmd\n";
  system @cmd;
  exit 2 if $?;
  
  $dll;
}

1;

=head1 EXAMPLES

TODO

=head1 SUPPORT

If something does not work as advertised, or the way that you think it
should, or if you have a feature request, please open an issue on this
project's GitHub issue tracker:

L<https://github.com/plicease/FFI-Platypus-Lang-Rust/issues>

=head1 CONTRIBUTING

If you have implemented a new feature or fixed a bug then you may make a
pull reequest on this project's GitHub repository:

L<https://github.com/plicease/FFI-Platypus-Lang-Rust/issues>

Caution: if you do this too frequently I may nominate you as the new
maintainer.  Extreme caution: if you like that sort of thing.

=head1 SEE ALSO

=over 4

=item L<FFI::Platypus>

The Core Platypus documentation.

=item L<Module::Build::FFI>

General MB class for FFI / Platypus.

=back

=head1 AUTHOR

Graham Ollis E<lt>plicease@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

