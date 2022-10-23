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

 #![crate_type = "cdylib"]
 
 // compile with: rustc add.rs
 
 #[no_mangle]
 pub extern "C" fn add(a:i32, b:i32) -> i32 {
     a+b
 }

Perl:

 use FFI::Platypus 1.00;
 my $ffi = FFI::Platypus->new( api => 1, lang => 'Rust' );
 $ffi->lib('./libadd.so');
 
 $ffi->attach( add => ['i32', 'i32'] => 'i32' );
 
 print add(1,2), "\n";  # prints 3

=head1 DESCRIPTION

This module provides native Rust types for L<FFI::Platypus> in order to
reduce cognitive load and concentrate on Rust and forget about C types.
This document also documents issues and caveats that I have discovered
in my attempts to work with Rust and FFI.

This module is somewhat experimental.  It is also available for adoption
for anyone either sufficiently knowledgeable about Rust or eager enough
to learn enough about Rust.  If you are interested, please send me a
pull request or two on the project's GitHub.

Note that in addition to using pre-compiled Rust libraries, you can
bundle Rust code with your Perl distribution using L<FFI::Build> and
L<FFI::Build::File::Cargo>.

=head2 name mangling

Rust names are "mangled" to handle features such as modules and the fact
that some characters in Rust names are illegal machine code symbol
names. For now that means that you have to tell Rust not to mangle the
names of functions that you are going to call from Perl.  You can
accomplish that like this:

 #[no_mangle]
 pub extern "C" fn foo() {
 }

You do not need to add this decoration to functions that you do not
directly call from Perl.  For example:

 fn bar() {
 }
 
 #[no_mangle]
 pub extern "C" fn foo() {
     bar();
 }

=head2 panics

Be careful about code that might C<panic!>.  A C<panic!> across an FFI
boundary is undefined behavior.  You will want to catch the panic
with a C<catch_unwind> and map to an appropriate result.

 use std::panic::catch_unwind;
 
 #[no_mangle]
 pub extern fn oopsie() -> u32 {
     let result = catch_unwind(|| {
         might_panic();
     });
     match result {
         OK(_) => 0,
         Err(_) -> 1,
     }
 }

=head2 structs

You can map a Rust struct to a Perl object by creating a C OO layer.
I suggest using the C<c_void> type aliased to an appropriate name so
that the struct can remain private to the Rust code.

For example, given a Foo struct:

 struct Foo {
     ...
 }
 
 impl Foo {
     fn new() -> Foo { ... }
     fn method1(&self) { ... }
 }

You can write a thin C layer:

 type CFoo = c_void;
 
 #[no_mangle]
 pub extern "C" fn foo_new(_class *const i8) -> *mut CFoo {
     Box::into_raw(Box::new(Foo::new())) as *mut CFoo
 }
 
 #[no_mangle]
 pub extern "C" fn foo_method1(f: *mut CFoo) {
     let f = unsafe { &*(f as *mut Foo) };
     f.method1();
 }
 
 #[allow(non_snake_case)]
 #[no_mangle]
 pub extern "C" fn foo_DESTROY(f: *mut CFoo) {
     unsafe { drop(Box::from_raw(f as *mut Foo)) };
 }

Which can be called easily from Perl:

 package Foo {
 
     use FFI::Platypus 1.00;
     my $ffi = FFI::Platypus->new( api => 1, lang => 'Rust' );
     $ffi->bundle; # see FFI::Build::File::Cargo for how to bundle
                   # your rust code...
     $ffi->type( 'object(Foo)' => 'CFoo' );
     $ffi->mangler(sub {
         my $symbol = shift;
         "foo_$symbol";
     });
     $ffi->attach( new     => [] => 'CFoo' );
     $ffi->attach( method1 => ['CFoo'] );
     $ffi->attach( DESTROY => ['CFoo'] );
 };
 
 my $foo = Foo->new;
 $foo->method1;
 # $foo->DESTROY implicitly called when it falls out of scope

=head2 returning strings

Passing in strings is not too hard, you can convert a Rust C<CString> into a Rust C<String>.
Return a string is a little tricky because of the ownership model.  Depending on how your
API works there are probably lot of approaches you might want to take.  One approach would
be to use thread local storage to store a C<CString> which you return.  It wastes a little
memory because once the string is copied into Perl space it isn't used again, but at least
it doesn't leak memory since it will be freed on the next call to your function.  Best of all
it doesn't require an C<unsafe> block.

 pub extern "C" fn return_string() -> *const i8 {
     thread_local! {
         static KEEP: RefCell<Option<CString>> = RefCell::new(None);
     }
 
     let my_string = String::from("foo");
     let c_string = CString::new(my_string).unwrap();
     let ptr = c_string.as_ptr();
     KEEP.with(|k| {
         *k.borrow_mut() = Some(c_string);
     });
 
     ptr
 }

From Perl:

 use FFI::Platypus 1.00;
 my $ffi = FFI::Platypus->new( api => 1, lang => 'Rust' );
 $ffi->bundle;
 $ffi->attach( return_string => [] => 'string' );

=head2 callbacks

Calling back into Perl from Rust is easy so long as you have the correct
types defined.  Consider a Rust function that takes a C function pointer:

 use std::ffi::CString;
 
 type PerlLog = extern fn(line: *const i8);
 
 #[no_mangle]
 pub extern "C" fn rust_log(logf: PerlLog) {
 
     let lines: [&str; 3] = [
         "Hello from rust!",
         "Something else.",
         "The last log line",
     ];
 
     for line in lines.iter() {
         // convert string slice to a C style NULL terminated string
         let line = CString::new(*line).unwrap();
         logf(line.as_ptr());
     }
 }

This can be called with a closure from Perl:

 use FFI::Platypus 1.00;
 
 my $ffi = FFI::Platypus->new( api => 1, lang => 'Rust' );
 $ffi->bundle;
 $ffi->type( '(string)->void' => 'PerlLog' );
 $ffi->attach( rust_log => ['PerlLog'] );
 
 my $perl_log = $ffi->closure(sub {
     my $message = shift;
     print "log> $message\n";
 });
 
 rust_log($perl_log);

Which outputs:

 $ perl callback.pl
 log> Hello from rust!
 log> Something else.
 log> The last log line

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

=head1 EXAMPLES

See the above L</SYNOPSIS> or the C<examples> directory that came with
this distribution.  This distribution comes with a whole module example
of a full object-oriented Rust/Perl extension including C<Makefile.PL>
Rust crate, Perl library and tests.  It lives in the C<examples/Person>
directory, or you can browse it on the web here:

L<https://github.com/PerlFFI/FFI-Platypus-Lang-Rust/tree/main/examples/Person>

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

=back

=cut

