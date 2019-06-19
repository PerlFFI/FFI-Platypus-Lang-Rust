use strict;
use warnings;
use Test::More;
use Test::Script;
use File::chdir;
use File::Which   qw( which);
use File::Glob    qw( bsd_glob );
use IPC::Run3     qw( run3 );

my $rustc = which 'rustc';

plan skip_all => 'Test requirest a rust compiler' unless $rustc;

subtest 'compile rust' => sub {
  local $CWD = 'examples';

  my @rust_source_files = bsd_glob '*.rs';

  plan tests => 0+@rust_source_files;

  foreach my $rust_source_file (@rust_source_files)
  {
    my @cmd = ($rustc, $rust_source_file);
    my($out, $err) = ('','');

    run3 \@cmd, \'', \$out, \$err;

    ok $? == 0, "@cmd";

    note "[out]\n$out" if $out;
    note "[err]\n$out" if $err;
  }

  dorename();

};

subtest 'perl ffi scripts' => sub {

  local $CWD = 'examples';

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

sub dorename
{
  if($^O eq 'darwin')
  {
    foreach my $old (bsd_glob("*.dylib"))
    {
      my $new = $old;
      $new =~ s{dylib$}{so};
      rename $old => $new;
    }
  }
}

done_testing;
