#!/usr/bin/env perl

use strict;
use warnings;
use FFI::Platypus 2.00;
use FFI::CheckLib qw( find_lib_or_die );
use File::Basename qw( dirname );

my $ffi = FFI::Platypus->new( api => 2, lang => 'Rust' );
$ffi->lib(
    find_lib_or_die(
        lib        => 'return',
        libpath    => [dirname __FILE__],
        systempath => [],
    )
);

$ffi->attach( theme_song_free     => ['opaque'] => 'void'   );

$ffi->attach( theme_song_generate => ['u8']     => 'opaque' => sub {
    my($xsub, $length) = @_;
    my $ptr = $xsub->($length);
    my $str = $ffi->cast( 'opaque' => 'string', $ptr );
    theme_song_free($ptr);
    $str;
});

print theme_song_generate(42), "\n";
