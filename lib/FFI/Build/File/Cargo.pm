package FFI::Build::File::Cargo;

use strict;
use warnings;
use 5.008001;
use File::chdir;
use FFI::CheckLib 0.11 qw( find_lib_or_exit );
use File::Copy qw( copy );
use Path::Tiny ();
use FFI::Build::File::Base 1.00 ();
use base qw( FFI::Build::File::Base );
use constant default_suffix => '.toml';
use constant default_encoding => ':utf8';

our $VERSION = '0.07';

=head1 NAME

FFI::Build::File::Cargo - Write Rust extensions for Perl!

=head1 SYNOPSIS

Crete a rust project in the C<ffi> directory that produces a dynamic library:

 nyx% ls -R
 .:
 Cargo.lock  Cargo.toml  src/
 
 ./src:
 lib.rs

Everything else works exactly like C.  See L<FFI::Build> for details.

=head1 DESCRIPTION

This module provides the necessary machinery to bundle rust code with your
Perl extension.  It uses L<FFI::Build> and C<cargo> to do the heavy lifting.

=cut

sub accept_suffix
{
  (qr/\/Cargo\.toml$/)
}

sub build_all
{
  my($self) = @_;
  $self->build_item;
}

sub build_item
{
  my($self) = @_;

  my $cargo_toml = Path::Tiny->new($self->path);

  my $platform;
  my $buildname;
  my $lib;

  if($self->build)
  {
    $platform = $self->build->platform;
    $buildname = $self->build->buildname;
    $lib = $self->build->file;
  }
  else
  {
    die "todo";
  }

  return $lib if -f $lib->path && !$lib->needs_rebuild($self->_deps($cargo_toml->parent, 1));

  {
    my $lib = Path::Tiny->new($lib)->relative($cargo_toml->parent)->stringify;
    local $CWD = $cargo_toml->parent->stringify;
    print "+cd $CWD\n";

    my @cmd = ('cargo', 'test');
    print "+@cmd\n";
    system @cmd;
    exit 2 if $?;

    @cmd = ('cargo', 'build', '--release');
    print "+@cmd\n";
    system @cmd;
    exit 2 if $?;

    my($dl) = find_lib_or_exit
      lib        => '*',
      libpath    => "$CWD/target/release",
      systempath => [],
    ;

    $dl = Path::Tiny->new($dl)->relative($CWD);
    my $dir = Path::Tiny->new($lib)->parent;
    print "+mkdir $dir\n";
    $dir->mkpath;

    print "+cp $dl $lib\n";
    copy($dl, $lib) or die "Copy failed: $!";

    print "+cd -\n";
  }

  $lib;
}

sub _deps
{
  my($self, $path, $is_root) = @_;

  my @list;

  foreach my $path ($path->children)
  {
    next if $is_root && $path->basename eq 'target';
    next if $path->basename =~ /\.bak$/;
    next if $path->basename =~ /~$/;
    if(-d $path)
    {
      push @list, $self->_deps($path, 0);
    }
    else
    {
      push @list, $path;
    }
  }

  @list;
}

1;

=head1 SEE ALSO

=over 4

=item L<FFI::Platypus>

The Core Platypus documentation.

=item L<FFI::Platypus::Lang::Rust>

Rust language plugin for Platypus.

=back

=head1 AUTHOR

Graham Ollis E<lt>plicease@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

