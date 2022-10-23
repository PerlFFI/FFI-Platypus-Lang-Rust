# FFI::Platypus::Lang::Rust ![static](https://github.com/PerlFFI/FFI-Platypus-Lang-Rust/workflows/static/badge.svg) ![linux](https://github.com/PerlFFI/FFI-Platypus-Lang-Rust/workflows/linux/badge.svg)

Documentation and tools for using Platypus with the Rust programming language

# SYNOPSIS

Rust:

```
#![crate_type = "cdylib"]

// compile with: rustc add.rs

#[no_mangle]
pub extern "C" fn add(a: i32, b: i32) -> i32 {
    a + b
}
```

Perl:

```perl
use FFI::Platypus 2.00;
use FFI::CheckLib qw( find_lib_or_die );
use File::Basename qw( dirname );

my $ffi = FFI::Platypus->new( api => 2, lang => 'Rust' );
$ffi->lib(
    find_lib_or_die(
        lib        => 'add',
        libpath    => [dirname __FILE__],
        systempath => [],
    )
);

$ffi->attach( add => ['i32', 'i32'] => 'i32' );

print add(1,2), "\n";  # prints 3
```

# DESCRIPTION

This module provides native Rust types for [FFI::Platypus](https://metacpan.org/pod/FFI::Platypus) in order to
reduce cognitive load and concentrate on Rust and forget about C types.
This document also documents issues and caveats that I have discovered
in my attempts to work with Rust and FFI.

This module is somewhat experimental.  It is also available for adoption
for anyone either sufficiently knowledgeable about Rust or eager enough
to learn enough about Rust.  If you are interested, please send me a
pull request or two on the project's GitHub.

Note that in addition to using pre-compiled Rust libraries, you can
bundle Rust code with your Perl distribution using [FFI::Build](https://metacpan.org/pod/FFI::Build) and
[FFI::Build::File::Cargo](https://metacpan.org/pod/FFI::Build::File::Cargo).

## name mangling

Rust names are "mangled" to handle features such as modules and the fact
that some characters in Rust names are illegal machine code symbol
names. For now that means that you have to tell Rust not to mangle the
names of functions that you are going to call from Perl.  You can
accomplish that like this:

```
#[no_mangle]
pub extern "C" fn foo() {
}
```

You do not need to add this decoration to functions that you do not
directly call from Perl.  For example:

```
fn bar() {
}

#[no_mangle]
pub extern "C" fn foo() {
    bar();
}
```

## panics

Be careful about code that might `panic!`.  A `panic!` across an FFI
boundary is undefined behavior.  You will want to catch the panic
with a `catch_unwind` and map to an appropriate result.

```perl
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
```

## structs

You can map a Rust struct to a Perl object by creating a C OO layer.
I suggest using the `c_void` type aliased to an appropriate name so
that the struct can remain private to the Rust code.

For example, given a Foo struct:

```
struct Foo {
    ...
}

impl Foo {
    fn new() -> Foo { ... }
    fn method1(&self) { ... }
}
```

You can write a thin C layer:

```
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
```

Which can be called easily from Perl:

```perl
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
```

## returning strings

Passing in strings is not too hard, you can convert a Rust `CString` into a Rust `String`.
Return a string is a little tricky because of the ownership model.  Depending on how your
API works there are probably lot of approaches you might want to take.  One approach would
be to use thread local storage to store a `CString` which you return.  It wastes a little
memory because once the string is copied into Perl space it isn't used again, but at least
it doesn't leak memory since it will be freed on the next call to your function.  Best of all
it doesn't require an `unsafe` block.

```perl
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
```

From Perl:

```perl
use FFI::Platypus 1.00;
my $ffi = FFI::Platypus->new( api => 1, lang => 'Rust' );
$ffi->bundle;
$ffi->attach( return_string => [] => 'string' );
```

## callbacks

Calling back into Perl from Rust is easy so long as you have the correct
types defined.  Consider a Rust function that takes a C function pointer:

```perl
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
```

This can be called with a closure from Perl:

```perl
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
```

Which outputs:

```
$ perl callback.pl
log> Hello from rust!
log> Something else.
log> The last log line
```

# METHODS

Generally you will not use this class directly, instead interacting with
the [FFI::Platypus](https://metacpan.org/pod/FFI::Platypus) instance.  However, the public methods used by
Platypus are documented here.

## native\_type\_map

```perl
my $hashref = FFI::Platypus::Lang::Rust->native_type_map;
```

This returns a hash reference containing the native aliases for the Rust
programming languages.  That is the keys are native Rust types and the
values are libffi native types.

# EXAMPLES

See the above ["SYNOPSIS"](#synopsis) or the `examples` directory that came with
this distribution.  This distribution comes with a whole module example
of a full object-oriented Rust/Perl extension including `Makefile.PL`
Rust crate, Perl library and tests.  It lives in the `examples/Person`
directory, or you can browse it on the web here:

[https://github.com/PerlFFI/FFI-Platypus-Lang-Rust/tree/main/examples/Person](https://github.com/PerlFFI/FFI-Platypus-Lang-Rust/tree/main/examples/Person)

# CAVEATS

- The `bool` type

    As of this writing, the `bool` type is in practice always a signed
    8 bit integer, but this has not been guaranteed by the Rust specification.
    This module assumes that it is a `sint8` type, but if that ever
    changes this module will need to be updated.

# SEE ALSO

- [FFI::Platypus](https://metacpan.org/pod/FFI::Platypus)

    The Core Platypus documentation.

- [FFI::Build::File::Cargo](https://metacpan.org/pod/FFI::Build::File::Cargo)

    Bundle Rust code with your FFI / Perl extension.

# AUTHOR

Author: Graham Ollis <plicease@cpan.org>

Contributors:

Andrew Grangaard (SPAZM)

# COPYRIGHT AND LICENSE

This software is copyright (c) 2015-2022 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
