package FFI::Platypus::Lang::Rust;

use strict;
use warnings;
use File::Glob qw( bsd_glob );
use File::Which qw( which );
use File::Spec;
use Env qw( @PATH );

# ABSTRACT: Documentation and tools for using Platypus with the Rust programming language
# VERSION

=head1 SYNOPSIS

Rust:

# EXAMPLE: examples/add.rs

Perl:

# EXAMPLE: examples/add.pl

=head1 DESCRIPTION

This module provides native Rust types for L<FFI::Platypus> in order to
reduce cognitive load and concentrate on Rust and forget about C types.
This document also documents issues and caveats that I have discovered
in my attempts to work with Rust and FFI.

Note that in addition to using pre-compiled Rust libraries, you can
bundle Rust code with your Perl distribution using L<FFI::Build> and
L<FFI::Build::File::Cargo>.

=head1 EXAMPLES

The examples in this discussion are bundled with this distribution and
can be found in the C<examples> directory.

=head2 Passing and Returning Integers

=head3 Rust Source

# EXAMPLE: examples/add.rs

=head3 Perl Source

# EXAMPLE: examples/add.pl

=head3 Execute

 $ rustc add.rs
 $ perl add.pl
 3

=head3 Notes

Basic types like integers and floating points are the easiest to pass
across the FFI boundary.  The Platypus Rust language plugin (this module)
provides the basic types used by Rust (for example: C<bool>, C<i32>, C<u64>,
C<f64>, C<isize> and others) will all work as a Rust programmer would expect.
This is nice because you don't have to think about what the equivalent types
would be in C when you are writing your Perl extension in Rust.

Rust symbols are "mangled" by default, which means that you cannot use
the name of the function from the source code without knowing what the
mangled name is.  Rust provides a function attribute C<#[no_mangle]>
which will tell the compiler not to mangle the name, making lookup of
the symbol possible from other programming languages like Perl.

Rust functions do not use the same ABI as C by default, so if you want
to be able to call Rust functions from Perl they need to be declared
as C<extern "C"> as in this example.

We also set the "crate type" to C<cdylib> in the first line to tell the
Rust compiler to generate a dynamic library that will be consumed by
a non-Rust language like Perl.

=head2 String Arguments

=head3 Rust Source

# EXAMPLE: examples/string/argument.rs

=head3 Perl Source

# EXAMPLE: examples/string/argument.pl

=head3 Execute

 $ rustc argument.rs
 $ perl argument.pl
 -1
 12

=head3 Notes

Strings are considerably more complicated for a number of reasons,
but for passing them into Rust code the main challenge is that the
representation is different from what C uses.  C Uses NULL terminated
strings and Rust uses a pointer and size combination that allows
NULLs inside strings.  Perls internal representation of strings is
actually closer to what Rust uses, but when Perl talks to other
languages it typically uses C Strings.

Getting a Rust string slice C<&str> requires a few stems

=over 4

=item We have to ensure the C pointer is not C<NULL>

We return C<-1> to indicate an error here.  As we can see from the
calling Perl code passing an C<undef> from Perl is equivalent to
passing in C<NULL> from C.

=item Wrap using C<Cstr>

We then wrap the pointer using an C<unsafe> block.  Even though
we know at this point that the pointer cannot be C<NULL> it could
technically be pointing to uninitialized or unaddressable memory.
This C<unsafe> block is unfortunately necessary, though it is
relatively isolated so it is easy to reason about and review.

=item Convert to UTF-8

If the string that we passed in is valid UTF-8 we can convert
it to a C<&str> using C<to_str> and compute the length of the
string.  Otherwise, we return -2 error.

=back

(This example is based on one provided in the
L<Rust FFI Omnibus|http://jakegoulding.com/rust-ffi-omnibus/string_arguments/>)

=head2 Returning allocated strings

=head3 Rust Source

# EXAMPLE: examples/string/return/return.rs

=head3 Perl Source

# EXAMPLE: examples/string/return/return.pl

=head3 Execute

 $ rustc return.rs
 $ perl return.pl
 💣 na na na na na na na na na na na na na na na na na na na na na na na na na na na na na na na na na na na na na na na na na na Batman! 💣

=head3 Notes

The big challenge of returning strings from Rust into Perl is
handling the ownership.  In this example we have a C API implemented
in Rust that returns a C NULL terminated string, but we have to
pass it back into Rust in order to deallocate it when we are done.

Unfortunately Platypus' C<string> type assumes that the callee
retains ownership of the returned string, so we have to get the
pointer instead as an C<opaque> so that we can later free it.
Before freeing it though we cast it into a Perl string.

In order to hide the complexities from caller of our
C<theme_song_generate> function, we use a function wrapper to
do all of that for us.

(This example is based on one provided in the
L<Rust FFI Omnibus|http://jakegoulding.com/rust-ffi-omnibus/string_return/>)

=head2 Returning allocated strings, but keeping ownership

=head3 Rust Source

# EXAMPLE: examples/string/return/keep.rs

=head3 Perl Source

# EXAMPLE: examples/string/return/keep.pl

=head3 Execute

 $ rustc keep.rs
 $ perl keep.pl
 💣 na Batman! 💣
 💣 na na Batman! 💣
 💣 na na na Batman! 💣
 💣 na na na na Batman! 💣
 💣 na na na na na Batman! 💣
 💣 na na na na na na Batman! 💣
 💣 na na na na na na na Batman! 💣
 💣 na na na na na na na na Batman! 💣
 💣 na na na na na na na na na Batman! 💣
 💣 na na na na na na na na na na Batman! 💣

=head3 Notes

For frequently called functions with smaller strings it may make more
sense to keep ownership of the string and just return a pointer.  Perl
makes its own copy on return anyway when you use the C<string> type.

In this example we use thread local storage to keep the C<CString>
until the next call when it will be freed.  Since we are using thread
local storage, it should even be safe to use this interface from a
threaded Perl program (although you should probably not be using
threaded Perl).

(This example is based on one provided in the
L<Rust FFI Omnibus|http://jakegoulding.com/rust-ffi-omnibus/string_arguments/>)

=head2 Return static strings

=head3 Rust Source

# EXAMPLE: examples/string/return/static.rs

=head3 Perl Source

# EXAMPLE: examples/string/return/static.pl

=head3 Execute

 $ rustc static.rs
 $ perl static.pl
 Hello, world!

=head3 Notes

Sometimes you just want to return a static NULL terminated string
from Rust to Perl.  This can sometimes be useful for returning
error messages.

=head2 Callbacks

=head3 Rust Source

# EXAMPLE: examples/callback.rs

=head3 Perl Source

# EXAMPLE: examples/callback.pl

=head3 Execute

 $ rustc callback.rs
 $ perl callback.pl
 log> Hello from rust!
 log> Something else.
 log> The last log line

=head3 Notes

Calling back into Perl from Rust is easy, so long as you have the correct
types defined.  The above Rust function takes a C function pointer.  We
can crate a Platypus closure object from Perl from a plain Perl sub and
pass the closure into Rust.

=head2 Slice arguments

=head3 Rust Source

# EXAMPLE: examples/slice.rs

=head3 Perl Source

# EXAMPLE: examples/slice.pl

=head3 Execute

 $ rustc slice.rs
 $ perl slice.pl
 -1
 12

=head3 Notes

A Rust slice is a pointer to a chunk of homogeneous data, and the
number of elements in the slice.  We can pass these two pieces in
from Perl and combine them into a slice in Rust.

This example sums the even numbers from a slice and returns the
result.

(This example is based on one provided in the
L<Rust FFI Omnibus|http://jakegoulding.com/rust-ffi-omnibus/slice_arguments/>)

=head2 Tuples

=head3 Rust Source

# EXAMPLE: examples/tuple.rs

=head3 Perl Source

# EXAMPLE: examples/tuple.pl

=head3 Execute

 $ rustc tuple.rs
 $ perl tuple.pl
 [21,9]

=head3 Notes

Rust's tuples do not have a standard representation that can be used
directly from Perl, but if your tuple contains only simple types you
can use the L<Platypus Record class|FFI::Platypus::Record> and translate
in Rust between the tuple and the C<struct>.

Because we are passing in and out the entire C<struct>, not pointers
to a C<struct> we don't have to worry about freeing them from Perl.
They just get allocated and freed on the stack.

(This example is based on one provided in the
L<Rust FFI Omnibus|http://jakegoulding.com/rust-ffi-omnibus/tuples/>)

=head2 Objects

=head3 Rust Source

# EXAMPLE: examples/Person/ffi/src/lib.rs

=head3 Perl Source

Main class:

# EXAMPLE: examples/Person/lib/Person.pm

Test:

# EXAMPLE: examples/Person/t/basic.t

=head3 Execute

 $ prove -lvm t/basic.t
 t/basic.t ..
 # Seeded srand with seed '20221023' from local date.
 ok 1
 ok 2
 ok 3
 1..3
 ok
 All tests successful.
 Files=1, Tests=3,  0 wallclock secs ( 0.02 usr  0.00 sys +  0.19 cusr  0.05 csys =  0.26 CPU)
 Result: PASS

=head3 Notes

This example includes excerpts from a full C<Person> dist which you can
find in the C<examples/Person> directory of this distribution.  You can
install it like a normal Perl distribution using L<ExtUtils::MakeMaker>,
or you can simply run the test file by using L<App::Prove>.  That is
because we are using L<FFI::Build> and L<FFI::Build::File::Cargo> to
build the Rust parts for us, which know how to work in either mode.
There are some stuff that we don't show you here for brevity: the
C<Makefile.PL> for example, and also the rust tests in C<ffi/src/test.rs>
which test the Rust crate by calling both its Rust and C interface.

What we have done here is created a Rust C<struct> and then written
C wrappers to create, query and modify the object.  We've also created
a destructor to free the object when we are done with it.

In terms of naming conventions, we use C<person_> prefix to denote that
these are methods for the Person class that we are creating.  This is
a common convention in C, where the only namespaces are adding prefixes
like this.  We also break the convention of using snake case for the
destructor C<person_DESTROY> because that will make it easier to bind
to from Perl.

When we creat the object we use C<Box::new> and C<Box::into_raw> to
create the object on the heap, and to return the opaque pointer back
to Perl.

For methods we can convert the raw pointers back into a Person C<struct>
using C<&*(p as *mut Person)> inside an C<unsafe> block.  In the case
of C<person_rename> we need a mutable version so we use C<&mut *(p as *mut Person)>
instead.

Finally when we are done with the object we can free it by simply
calling C<Box::from_raw>.  When it falls out of scope it will be freed.

On the Perl side, we use the C<mangler> method to prepend all symbols
with the C<person_> prefix, so that we can attach with just the method
name.

We also create a Platypus type for C<object(Person)> and give it the
alias C<person_t>.  Now we can use it as an argument and return type.
This is really a pointer to an opaque (to perl) C<struct>.

If you look at just the test, then you can't even tell that the implementation
for our Person class is in Rust, which is good because your users shouldn't
have to care!

=head2 Panic!

=head3 Rust Source

# EXAMPLE: examples/panic.rs

=head3 Perl Source

# EXAMPLE: examples/panic.pl

=head3 Execute

 $ perl panic.pl
 thread '<unnamed>' panicked at 'oops!', panic.rs:7:9
 note: run with `RUST_BACKTRACE=1` environment variable to display a backtrace
 -1
 5

=head3 Notes

Be cautious about code that might C<panic!>.  A C<panic!> across the FFI
boundary is undefined behavior and usually results in a crash.  You will
want to catch the panic with a C<catch_unwind> and map to an appropriate
error result.  In this example, we have a function that returns the
integer passed in divided by 2.  It does not like odd numbers though and
will panic.  So we catch the panic and return -1 to indicate an error.
As you can see from the run we also get a rather ugly diagnostic, but
at least our program didn't crash!

=head1 METHODS

Generally you will not use this class directly, instead interacting with
the L<FFI::Platypus> instance.  However, the public methods used by
Platypus are documented here.

=head2 native_type_map

 my $hashref = FFI::Platypus::Lang::Rust->native_type_map;

This returns a hash reference containing the native aliases for the Rust
programming languages.  That is the keys are native Rust types and the
values are libffi native types.

=cut

sub native_type_map
{
  require FFI::Platypus;
  {
    u8       => 'uint8',
    u16      => 'uint16',
    u32      => 'uint32',
    u64      => 'uint64',
    i8       => 'sint8',
    i16      => 'sint16',
    i32      => 'sint32',
    i64      => 'sint64',
    binary32 => 'float',    # need to check this is right
    binary64 => 'double',   #  "    "  "     "    "  "
    f32      => 'float',
    f64      => 'double',
    bool     => 'sint8',    # in practice, but not guaranteed by spec
    usize    => FFI::Platypus->type_meta('size_t')->{ffi_type},
    isize    => FFI::Platypus->type_meta('ssize_t')->{ffi_type},
  },
}

1;

=head1 CAVEATS

=over 4

=item The C<bool> type

As of this writing, the C<bool> type is in practice always a signed
8 bit integer, but this has not been guaranteed by the Rust specification.
This module assumes that it is a C<sint8> type, but if that ever
changes this module will need to be updated.

=back

=head1 SEE ALSO

=over 4

=item L<FFI::Platypus>

The Core Platypus documentation.

=item L<FFI::Build::File::Cargo>

Bundle Rust code with your FFI / Perl extension.

=item L<The Rust FFI Omnibus|http://jakegoulding.com/rust-ffi-omnibus/>

Includes a number of examples of calling Rust from other languages.

=item L<The Rustonomicon - Foreign Function Interface|https://doc.rust-lang.org/nomicon/ffi.html>

Detailed Rust documentation on crossing the FFI barrier.

=item L<The Rust Programming Language - Unsafe Rust|https://doc.rust-lang.org/book/ch19-01-unsafe-rust.html>

Unsafe Rust in the Rust Programming Language book.

=back

=cut

