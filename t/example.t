use Test2::V0 -no_srand => 1;
use Test::Script;
use File::chdir;
use File::Which   qw( which);
use File::Glob    qw( bsd_glob );
use Capture::Tiny qw( capture_merged );

my $rustc = which 'rustc';

foreach my $dir (qw( examples examples/old examples/string examples/string/return ))
{

  subtest $dir => sub {
    local $CWD = $dir;

    subtest 'compile rust' => sub {

      my @rust_source_files = bsd_glob '*.rs';

      plan tests => 0+@rust_source_files;

      foreach my $rust_source_file (@rust_source_files)
      {
        my @cmd = ($rustc, $rust_source_file);

        my($out, $ret) = capture_merged {
          print "+@cmd";
          system @cmd;
          $?;
        };

        ok($ret == 0, "@cmd")
          ? note $out
          : diag $out;
      }

    };

    subtest 'perl ffi scripts' => sub {

      my @scripts = bsd_glob '*.pl';

      plan skip_all => 'test not supported on Windows' if $^O eq 'MSWin32';
      plan tests => 0+@scripts;

      foreach my $script (@scripts)
      {
        subtest $script => sub {
          script_compiles $script;

          my($out, $err) = ('','');
          script_runs $script, { stdout => \$out, stderr => \$err };

          note "[out]\n$out" if $out;
          note "[err]\n$out" if $err;
        }
      }
    };

    unlink $_ for map { bsd_glob $_ } qw( *.so *.dylib *.dll );
  };
}

done_testing;
