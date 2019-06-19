use strict;
use warnings;
use Test::More;
use FFI::CheckLib qw( find_lib );
use FFI::Platypus;

my $libtest = find_lib lib => 'test', libpath => 't/ffi';
plan skip_all => 'test requires a rust compiler'
  unless $libtest;

my $ffi = FFI::Platypus->new;
$ffi->lang('Rust');
$ffi->lib($libtest);

$ffi->attach(i32_sum => ['i32', 'i32'] => 'i32');

is i32_sum(1,2), 3, 'i32_sum(1,2) = 3';

done_testing;
