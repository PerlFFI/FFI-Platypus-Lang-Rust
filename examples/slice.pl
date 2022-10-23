#!/usr/bin/env perl

use strict;
use warnings;
use FFI::Platypus 2.00;
use FFI::CheckLib qw( find_lib_or_die );
use File::Basename qw( dirname );

my $ffi = FFI::Platypus->new( api => 2, lang => 'Rust' );
$ffi->lib(
    find_lib_or_die(
        lib        => 'slice',
        libpath    => [dirname __FILE__],
        systempath => [],
    )
);

$ffi->attach( sum_of_even => ['u32*', 'usize'] => 'i64' );

print sum_of_even(undef, 0), "\n";          # print -1
print sum_of_even([1,2,3,4,5,6], 6), "\n";  # print 12
