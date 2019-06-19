use strict;
use warnings;
use Test::More;
use FFI::Platypus;
use FFI::CheckLib qw( find_lib );

subtest 'attach' => sub {

  my $libtest = find_lib lib => 'test', libpath => 't/ffi';
  plan skip_all => 'test requires a rust compiler'
    unless $libtest;

  my $ffi = FFI::Platypus->new;
  $ffi->lang('Rust');
  $ffi->lib($libtest);

  $ffi->attach(i32_sum => ['i32', 'i32'] => 'i32');

  is i32_sum(1,2), 3, 'i32_sum(1,2) = 3';

};

subtest 'types test' => sub {

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
