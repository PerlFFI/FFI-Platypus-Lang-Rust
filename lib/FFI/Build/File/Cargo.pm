package FFI::Build::File::Cargo;

use strict;
use warnings;
use 5.008001;
use File::chdir;
use FFI::CheckLib 0.11 qw( find_lib_or_die );
use File::Copy qw( copy );
use Path::Tiny ();
use FFI::Build::File::Base 1.00 ();
use Env::ShellWords qw( @PERL_FFI_CARGO_FLAGS );
use base qw( FFI::Build::File::Base );
use constant default_suffix => '.toml';
use constant default_encoding => ':utf8';

# ABSTRACT
# VERSION

=head1 SYNOPSIS

Crete a rust project in the C<ffi> directory that produces a dynamic library:

 $ cargo new --lib --name my_lib ffi
       Created library `my_lib` package

Add this to your C<ffi/Cargo.toml> file to get dynamic libraries:

 [lib]
 crate-type = ["cdylib"]

Your library goes in C<lib/MyLib.pm>:

 package MyLib;
 
 use FFI::Platypus 1.00;
 
 my $ffi = FFI::Platypus->new( api => 1, lang => 'Rust' );
 # configure platypus to use the bundled Rust code
 $ffi->bundle;
 
 ...

Your C<Makefile.PL>:

 use ExtUtils::MakeMaker;
 use FFI::Build::MM;
 
 my $fbmm = FFI::Build::MM->new;
 
 WriteMakefile($fbmm->mm_args(
     ABSTRACT       => 'My Lib',
     DISTNAME       => 'MyLib',
     NAME           => 'MyLib',
     VERSION_FROM   => 'lib/MyLib.pm',
     BUILD_REQUIRES => {
         'FFI::Build::MM'          => '1.00',
         'FFI::Build::File::Cargo' => '0.07',
     },
     PREREQ_PM => {
         'FFI::Platypus'             => '1.00',
         'FFI::Platypus::Lang::Rust' => '0.07',
     },
 ));
 
 sub MY::postamble {
     $fbmm->mm_postamble;
 }

or alternatively, your C<dist.ini>:

 [FFI::Build]

=head1 DESCRIPTION

This module provides the necessary machinery to bundle rust code with your
Perl extension.  It uses L<FFI::Build> and C<cargo> to do the heavy lifting.

A complete example comes with this distribution in the C<examples/Person>
directory, including tests.  You can browse this example on the web here:

L<https://github.com/PerlFFI/FFI-Platypus-Lang-Rust/tree/main/examples/Person>

The distribution that follows the pattern above works just like a regular
Pure-Perl or XS distribution, except:

=over 4

=item make

Running the C<make> step builds the Rust library as a dynamic library using
cargo, and runs the crate's tests if any are available.  It then moves the
resulting dynamic library in to the appropriate location in C<blib> so that
it can be found at test and runtime.

=item prove

If you run the tests using C<prove -l> (that is, without building the
distribution), Platypus will find the rust crate in the C<ffi> directory,
build that and use it on the fly.  This makes it easier to test your
distribution with less explicit building.

=back

This module is smart enough to check the timestamps on the appropriate files
so the library won't need to be rebuilt if the source files haven't changed.

For more details using Perl + Rust with FFI, see L<FFI::Platypus::Lang::Rust>.

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

    my @cargo_flags = defined $ENV{PERL_FFI_CARGO_FLAGS}
      ? @PERL_FFI_CARGO_FLAGS
      : ('--release');

    my @cmd = ('cargo', 'test', @cargo_flags);
    print "+@cmd\n";
    system @cmd;
    die "error running cargo test" if $?;

    @cmd = ('cargo', 'build', @cargo_flags);
    print "+@cmd\n";
    system @cmd;
    die "error running cargo build" if $?;

    my($dl) = find_lib_or_die
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

=head1 ENVIRONMENT

=over 4

=item C<PERL_FFI_CARGO_FLAGS>

This environment variable changes the flags that are passed into
C<cargo test> and C<cargo build>.

By default this module passes C<--release> into both C<cargo test> and
C<cargo build>.  It does this so that you will get optimized libraries
when your Perl extension is installed.  You may require a different
profile when testing so you can, for example, set this environment
variable to something else:

 $ export PERL_FFI_CARGO_FLAGS='--profile test'
 $ ...

=back

=head1 SEE ALSO

=over 4

=item L<FFI::Platypus>

The Core Platypus documentation.

=item L<FFI::Platypus::Lang::Rust>

Rust language plugin for Platypus.

=back

=cut

