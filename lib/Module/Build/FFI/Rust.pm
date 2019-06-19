package Module::Build::FFI::Rust;

use strict;
use warnings;
use Config;
use File::Glob qw( bsd_glob );
use File::Which qw( which );
use File::chdir;
use File::Copy qw( copy );
use base qw( Module::Build::FFI );

our $VERSION = '0.06';

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
  my $cargo = which('cargo');
  
  return (!!$rustc) && (!!$cargo);
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

  if(@$src_dir > 1)
  {
    print STDERR "Module::Build::FFI::Rust only supports one ffi directory";
    exit 2;
  }
  
  $src_dir = $src_dir->[0];
  
  $target_dir = $src_dir unless defined $target_dir;
  
  my $dll = File::Spec->catfile($target_dir, "$name.$Config{dlext}");

  if(-e File::Spec->catfile($src_dir, 'Cargo.toml'))
  {
    $self->add_to_cleanup("$src_dir/target");
  
    do {
      local $CWD = $src_dir;
      my @cmd = ('cargo', 'build', '--release');
      print "@cmd\n";
      system @cmd;
      exit 2 if $?;
    };
    
    # Note: $Config{dlext} is frequently the right extension to look for,
    # some platforms however have exceptions.
    my $dlext = $Config{dlext};
    # On OS X rust produces a dynamic library, but Perl extensions are
    # built as bundles.  Platypus can work with either and doesn't care
    # about the extension, so we install the dylib as a bundle.
    if($^O eq 'darwin')
    { $dlext = 'dylib' }
    # On Strawberry Perl of recent vintage they use .xs.dll as the dynamic
    # library extension.
    elsif($^O eq 'MSWin32')
    { $dlext = 'dll' }

    my($build_dll) = bsd_glob("$src_dir/target/release/*.$dlext");
    copy($build_dll, $dll) || do {
      print STDERR "copy failed for\n";
      print STDERR "  $build_dll => $dll\n";
      print STDERR "reason: $!\n";
      exit 2;
    };
    
    my $test_dirs = $self->notes('ffi_rust_dirs');
    my %test_dirs = $test_dirs ? map { $_ => 1 } @$test_dirs : ();
    $test_dirs{$src_dir} = 1;
    $self->notes('ffi_rust_dirs' => [keys %test_dirs]);
  }
  
  else
  {
    print STDERR "== WARNING WARNING WARNING ==\n";
    print STDERR "\n";
    print STDERR "building rust project without cargo is deprecated and will be removed\n";
    print STDERR "from a future version of Module::Build::FFI::Rust!  But not before\n";
    print STDERR "31 December 2015.\n";
    print STDERR "\n";
    print STDERR "== WARNING WARNING WARNING ==\n";

    my @sources = bsd_glob("$src_dir/*.rs");
  
    return unless @sources;
  
    if(@sources != 1)
    {
      print STDERR "Only one Rust source file at a time please.\n";
      print STDERR "You appear to have more than one in $src_dir.\n";
      exit 2;
    }

    my $rustc = which('rustc');
  
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
  }
  
  $dll;
}

sub ACTION_testrust
{
  my($self) = @_;

  $self->notes('ffi_rust_test_fail' => 0);
  
  my $test_dirs = $self->notes('ffi_rust_dirs');
  return unless $test_dirs;
  
  foreach my $dir (@$test_dirs)
  {
    local $CWD = $dir;
    my @cmd = ('cargo', 'test');
    print "@cmd\n";
    system @cmd;
    $self->notes('ffi_rust_test_fail' => 1) if $?;
  }
}

sub ACTION_test
{
  my($self) = @_;
  $self->depends_on('testrust');
  $self->SUPER::ACTION_test;
  if($self->notes('ffi_rust_test_fail'))
  {
    exit 2;
  }
}

1;

=head1 EXAMPLES

For a complete example working example, see this module which calculates
fibonacci numbers using Rust.

L<https://github.com/plicease/Fibonacci-FFI>

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

