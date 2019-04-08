#!/usr/bin/env perl

use v5.12;
use warnings;
use FFI::Platypus;

my $ffi = FFI::Platypus->new;
$ffi->lang('Rust');
$ffi->lib('./libstring.so');
$ffi->attach(hello_rust => [] => 'string');

say hello_rust();
