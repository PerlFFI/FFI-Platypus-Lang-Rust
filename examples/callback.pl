#!/usr/bin/env perl

use strict;
use warnings;
use FFI::Platypus 2.00;
use FFI::CheckLib qw( find_lib_or_die );
use File::Basename qw( dirname );

my $ffi = FFI::Platypus->new( api => 2, lang => 'Rust' );
$ffi->lib(
    find_lib_or_die(
        lib        => 'callback',
        libpath    => [dirname __FILE__],
        systempath => [],
    )
);

$ffi->type( '(string)->void' => 'PerlLog' );
$ffi->attach( rust_log => ['PerlLog'] );

my $perl_log = $ffi->closure(sub {
    my $message = shift;
    print "log> $message\n";
});

rust_log($perl_log);
