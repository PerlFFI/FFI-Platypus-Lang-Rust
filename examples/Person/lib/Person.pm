package Person;

use strict;
use warnings;
use FFI::Platypus 2.00;

our $VERSION = '2.00';

my $ffi = FFI::Platypus->new( api => 2, lang => 'Rust' );

# use the bundled code as a library
$ffi->bundle;

# use the person_ prefix
$ffi->mangler(sub {
    my $symbol = shift;
    return "person_$symbol";
});

# Create a custom type mapping for the person_t (C) and Person (perl)
# classes.
$ffi->type( 'object(Person)' => 'person_t' );

$ffi->attach( new          => [ 'string', 'string', 'i32' ] => 'person_t' );
$ffi->attach( name         => [ 'person_t' ] => 'string' );
$ffi->attach( lucky_number => [ 'person_t' ] => 'i32' );
$ffi->attach( DESTROY      => [ 'person_t' ] );

1;
