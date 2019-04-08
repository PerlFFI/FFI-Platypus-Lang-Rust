#!/usr/bin/env perl

use v5.12;
use warnings;
use FFI::Platypus;

my $ffi = FFI::Platypus->new;
$ffi->lang('Rust');
$ffi->type('opaque' => 'Point');
$ffi->lib('./libpoints.so');
$ffi->attach(make_point => [ 'i32', 'i32' ] => 'Point');
$ffi->attach(get_distance => ['Point', 'Point'] => 'f64');

say get_distance(make_point(2,2), make_point(4,4));
