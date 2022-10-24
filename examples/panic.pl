#!/usr/bin/env perl

use strict;
use warnings;
use FFI::Platypus 2.00;
use FFI::CheckLib qw( find_lib_or_die );
use File::Basename qw( dirname );

my $ffi = FFI::Platypus->new( api => 2, lang => 'Rust' );
$ffi->lib(
    find_lib_or_die(
        lib        => 'panic',
        libpath    => [dirname __FILE__],
        systempath => [],
    )
);

$ffi->attach( oopsie => ['u32'] => 'i64' );

print oopsie(5), "\n";   # -1
print oopsie(10), "\n";  # 5
