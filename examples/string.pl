#!/usr/bin/env perl

use strict;
use warnings;
use FFI::Platypus;

my $ffi = FFI::Platypus->new;
$ffi->lang('Rust');
$ffi->lib('./libstring.so');
$ffi->attach(hello_rust => [] => 'string');

print hello_rust(), "\n";
