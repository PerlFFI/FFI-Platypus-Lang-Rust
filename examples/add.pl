#!/usr/bin/env perl

use strict;
use warnings;
use FFI::Platypus 1.00;
use FFI::CheckLib qw( find_lib_or_die );
use File::Basename qw( dirname );

my $ffi = FFI::Platypus->new( api => 1, lang => 'Rust' );
$ffi->lib(
    find_lib_or_die(
        lib        => 'add',
        libpath    => [dirname __FILE__],
        systempath => [],
    )
);

$ffi->attach( add => ['i32', 'i32'] => 'i32' );

print add(1,2), "\n";  # prints 3
