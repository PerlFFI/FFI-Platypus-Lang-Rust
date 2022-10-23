use Test2::V0 -no_srand => 1;
use File::chdir;
use Path::Tiny qw( path );
use Config;
use Capture::Tiny qw( capture );

sub run_ok
{
  my @command = @_;
  my($out, $err, $exit) = capture {
    system @command;
  };

  is $exit, 0, "run> @command";
  note "[out]\n$out" if $out ne '';
  note "[err]\n$err" if $out ne '';
}

subtest 'build and test' => sub {

  local $CWD = 'examples/Person';

  run_ok $^X, 'Makefile.PL';
  run_ok $Config{make};
  run_ok $Config{make}, 'test';
  run_ok $Config{make}, 'realclean';

};

path('examples/Person/ffi/target')->remove_tree;

done_testing;
