#!/usr/bin/env perl

use strict;
use warnings;
use File::Basename qw( dirname );
use FFI::Platypus 1.00;
use FFI::CheckLib qw( find_lib_or_die );

my $ffi = FFI::Platypus->new( api => 1, lang => 'Rust' );
$ffi->type('opaque' => 'Point');
$ffi->lib(
    find_lib_or_die(
        lib        => 'points',
        libpath    => [dirname __FILE__],
        systempath => [],
    )
);
$ffi->attach(make_point => [ 'i32', 'i32' ] => 'Point');
$ffi->attach(get_distance => ['Point', 'Point'] => 'f64');
$ffi->attach(drop_point => [ 'Point' ]);

my($p1,$p2) = (make_point(2,2), make_point(4,4));
print get_distance($p1,$p2), "\n";

drop_point($p1);
drop_point($p2);
