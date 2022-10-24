use Test2::V0;
use Person;

my $plicease = Person->new("Graham Ollis", 42);

is $plicease->name, "Graham Ollis";
is $plicease->lucky_number, 42;

$plicease->rename("Graham THE Ollis");

is $plicease->name, "Graham THE Ollis";

done_testing;
