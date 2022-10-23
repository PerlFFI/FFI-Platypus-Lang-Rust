#!/usr/bin/env perl

use strict;
use warnings;
use FFI::Platypus 2.00;
use FFI::CheckLib qw( find_lib_or_die );
use File::Basename qw( dirname );

my $ffi = FFI::Platypus->new( api => 2, lang => 'Rust' );
$ffi->lib(
    find_lib_or_die(
        lib        => 'argument',
        libpath    => [dirname __FILE__],
        systempath => [],
    )
);

$ffi->attach( how_many_characters => ['string'] => 'isize' );

print how_many_characters(undef), "\n";           # prints -1
print how_many_characters("frooble bits"), "\n";  # prints 12
