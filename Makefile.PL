use strict;
use warnings;

BEGIN {
  unless(eval q{ use 5.008001; 1 }) {
    print "Perl 5.008001 or better required\n";
    exit;
  }
}

use 5.008001;
use lib 'lib';
use ExtUtils::MakeMaker 6.64;
use File::Which qw( which );
use FFI::Build::MM;

unless(which('cargo'))
{
  print "This distribution requires that you have cargo/rust installed\n";
  exit;
}

my $fbmm = FFI::Build::MM->new;

my %WriteMakefileArgs = (
  NAME               => 'FFI::Platypus::Lang::Rust',
  DISTNAME           => 'FFI-Platypus-Lang-Rust',
  AUTHOR             => "Graham Ollis <plicease\@cpan.org>",
  VERSION_FROM       => 'lib/FFI/Platypus/Lang/Rust.pm',
  ABSTRACT_FROM      => 'lib/FFI/Platypus/Lang/Rust.pm',
  LICENSE            => 'perl',
  MIN_PERL_VERSION   => '5.008001',
  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker' => '6.64',
    'File::Which'         => 0,
    'FFI::Build::MM'      => '0.99',
    'FFI::CheckLib'       => 0.11,
    'File::chdir'         => 0,
    'Path::Tiny'          => 0,
  },
  BUILD_REQUIRES => {
    # ...
  },
  PREREQ_PM => {
    'File::chdir'         => 0,
    'Path::Tiny'          => 0,
    'FFI::CheckLib'       => 0.11,
  },
  TEST_REQUIRES => {
    'IPC::Run3'           => 0,
    'Test::Script'        => 0,
  },
  META_MERGE => {
    'meta-spec' => { version => 2 },
    resources => {
      bugtracker => {
        web => 'https://github.com/Perl5-FFI/FFI-Platypus-Lang-Rust/issues',
      },
      repository => {
        type => 'git',
        url => 'https://github.com/Perl5-FFI/FFI-Platypus-Lang-Rust.git',
        web => 'https://github.com/Perl5-FFI/FFI-Platypus-Lang-Rust',
      },
      x_IRC => 'irc://irc.perl.org/#native',
    },
  },
  clean => { FILES => 'FFI-Platypus-Lang-Rust-* t/ffi/target examples/*.so' },
);

WriteMakefile($fbmm->mm_args(%WriteMakefileArgs));

sub MY::postamble {
  $fbmm->mm_postamble;
}
