use strict;
use warnings;
use Test::More;
use FFI::Platypus::Lang::Rust;

my $types = FFI::Platypus::Lang::Rust->native_type_map;

foreach my $rust_type (sort keys %$types)
{
  note sprintf "%-10s %s\n", $rust_type, $types->{$rust_type};
}

pass 'okay';

done_testing;
