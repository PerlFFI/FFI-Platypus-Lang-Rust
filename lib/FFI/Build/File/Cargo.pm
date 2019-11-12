package FFI::Build::File::Cargo;

use strict;
use warnings;
use 5.008001;
use File::chdir;
use FFI::CheckLib 0.11 qw( find_lib_or_exit );
use File::Copy qw( copy );
use Path::Tiny ();
use base qw( FFI::Build::File::Base );
use constant default_suffix => '.toml';
use constant default_encoding => ':utf8';

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

1;
