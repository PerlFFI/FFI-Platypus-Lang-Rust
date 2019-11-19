#!/usr/bin/env perl

use strict;
use warnings;
use FFI::CheckLib qw( find_lib_or_die );
use File::Basename qw( dirname );
use FFI::Platypus 1.00;

my $ffi = FFI::Platypus->new( api => 1, lang => 'Rust');
$ffi->lang('Rust');
$ffi->lib(
    find_lib_or_die(
        lib        => 'string',
        libpath    => [dirname __FILE__],
        systempath => [],
    )
);
$ffi->lib('./libstring.so');
$ffi->attach(hello_rust => [] => 'string');

print hello_rust(), "\n";
