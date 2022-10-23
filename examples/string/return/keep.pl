#!/usr/bin/env perl

use strict;
use warnings;
use FFI::Platypus 2.00;
use FFI::CheckLib qw( find_lib_or_die );
use File::Basename qw( dirname );

my $ffi = FFI::Platypus->new( api => 2, lang => 'Rust' );
$ffi->lib(
    find_lib_or_die(
        lib        => 'keep',
        libpath    => [dirname __FILE__],
        systempath => [],
    )
);

$ffi->attach( theme_song_generate => ['u8'] => 'string' );

print theme_song_generate($_), "\n" for 1..10;
