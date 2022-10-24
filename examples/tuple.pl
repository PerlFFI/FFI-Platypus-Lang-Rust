#!/usr/bin/env perl

use strict;
use warnings;
use FFI::Platypus 2.00;
use FFI::C;
use FFI::CheckLib qw( find_lib_or_die );
use File::Basename qw( dirname );

my $ffi = FFI::Platypus->new( api => 2, lang => 'Rust' );
$ffi->lib(
    find_lib_or_die(
        lib        => 'tuple',
        libpath    => [dirname __FILE__],
        systempath => [],
    )
);

package Tuple;

use FFI::Platypus::Record;

use overload
  '""' => sub { shift->as_string },
  bool => sub { 1 }, fallback => 1;  

record_layout_1($ffi, qw(
  u32 x
  u32 y
));

sub as_string {
  my $self = shift;
  sprintf "[%d,%d]", $self->x, $self->y;
}

package main;

$ffi->type('record(Tuple)' => 'tuple_t');
$ffi->attach( flip_things_around => ['tuple_t'] => 'tuple_t' );

print flip_things_around(Tuple->new(x => 10, y => 20)), "\n";
