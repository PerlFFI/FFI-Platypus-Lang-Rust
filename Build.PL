BEGIN {
  unless(eval q{ use 5.008001; 1 }) {
    print "Perl 5.008001 or better required\n";
    exit;
  }
}
use strict;
use warnings;
use lib 'inc';
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
  exit;
}

my $builder = My::ModuleBuild->new(
  module_name   => 'FFI::Platypus::Lang::Rust',
  dist_abstract => 'Tools and documentation for using Platypus with the Rust '.
                   'programming language',
  dist_author   => [ 'Graham Ollis <plicease@cpan.org>' ],
  license       => 'perl',
  configure_requires => {
    'Module::Build' => 0.38,
  },
  build_requires => {
  },
  requires => {
    'perl',         => '5.008001',
    'FFI::Platypus' => '0.16',
  },
);

$builder->add_to_cleanup(
  '*.bak',
  'FFI-Platypus-Lang-Rust-*',
);

$builder->create_build_script;
