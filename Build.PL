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

my $rustc;

foreach my $path (@PATH)
{
  my $try = File::Spec->catfile($path, "rustc");
  if(-e $try)
  {
    my $version = `$try -V`;
    if($? == 0)
    {
      print "found rustc:\n";
      print "$version\n";
      $rustc = $try;
      last;
    }
  }
}

unless($rustc)
{
  print "Unable to find rustc.  Please make sure it is in the PATH.\n";
  print "You should still be able to use pre-compiled rust dynamic libs.\n";
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
    'Module::Build::FFI' => '0.18'
  },
  build_requires => {
    'Module::Build' => 0.38,
    'File::Which' => 0,
    'Module::Build::FFI' => '0.18'
  },
  test_requires => {
    'FFI::CheckLib' => 0,
    'Test::Script'  => '1.09',
    'File::chdir'   => 0,
    'IPC::Run3'     => 0,
  },
  requires => {
    'perl',         => '5.008001',
    'FFI::Platypus' => '0.18',
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
);

$builder->add_to_cleanup(
  '*.bak',
  'examples/*.so',
  'examples/*.dll',
  'examples/*.bundle',
  'examples/*.dylib',
  'libtest/*.so',
  'libtest/*.dll',
  'libtest/*.bundle',
  'libtest/*.dylib',
  'FFI-Platypus-Lang-Rust-*',
);

$builder->create_build_script;
