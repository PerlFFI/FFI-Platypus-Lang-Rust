BEGIN {
  unless(eval q{ use 5.008001; 1 }) {
    print "Perl 5.008001 or better required\n";
    exit;
  }
}
use strict;
use warnings;
use lib 'inc';
use lib 'lib';
use My::ModuleBuild;
use Env qw( @PATH );
use File::Spec;
use File::Which qw( which );

unless(which('cargo'))
{
  print STDERR <<DIAG;
unable to find cargo in your PATH which you will likely need if you are
going to build any extensions with bundled Rust code.
DIAG
}

my $builder = My::ModuleBuild->new(
  module_name   => 'FFI::Platypus::Lang::Rust',
  dist_abstract => 'Documentation and tools for using Platypus with the Rust '.
                   'programming language',
  dist_author   => [ 'Graham Ollis <plicease@cpan.org>' ],
  license       => 'perl',
  configure_requires => {
    'Module::Build' => 0.38,
    'File::Which' => 0,
    'Module::Build::FFI' => '0.49',
    'File::chdir'   => 0,
  },
  build_requires => {
    'Module::Build' => 0.38,
    'File::Which' => 0,
    'Module::Build::FFI' => '0.49',
    'File::chdir'   => 0,
  },
  test_requires => {
    'FFI::CheckLib' => 0,
    'Test::Script'  => '1.09',
    'File::chdir'   => 0,
    'IPC::Run3'     => 0,
  },
  requires => {
    'perl',         => '5.008001',
    'FFI::Platypus' => '0.88',
    'File::Which'   => 0,
  },
  meta_merge => {
    resources => {
      repository => "http://github.com/plicease/FFI-Platypus-Lang-Rust",
      bugtracker => "http://github.com/plicease/FFI-Platypus-Lang-Rust/issues",
      x_IRC => "irc://irc.perl.org/#native",
    },
    no_index => {
      directory => [ 'examples' ],
    },
  },
  ffi_libtest_dir => [ 't/ffi' ],
);

$builder->add_to_cleanup(
  '*.bak',
  'examples/*.so',
  'examples/*.dll',
  'examples/*.bundle',
  'examples/*.dylib',
  't/ffi/*.so',
  't/ffi/*.dll',
  't/ffi/*.bundle',
  't/ffi/*.dylib',
  't/ffi/Cargo.lock',
  'FFI-Platypus-Lang-Rust-*',
);

$builder->create_build_script;
