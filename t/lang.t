use strict;
use warnings;
use Test::More;
use FFI::Platypus;

subtest 'Foo constructor' => sub {

  my $ffi = FFI::Platypus->new(lang => 'Rust');
  
  eval { $ffi->type('int') };
  isnt $@, '', 'int is not an okay type';
  note $@;
  eval { $ffi->type('i32') };
  is $@, '', 'i32 is an okay type';
  eval { $ffi->type('sint16') };
  is $@, '', 'sint16 is an okay type';
  
  is $ffi->sizeof('i16'), 2, 'sizeof i16 = 2';
  is $ffi->sizeof('u32'), 4, 'sizeof u32_t = 4';
  
};

done_testing;
