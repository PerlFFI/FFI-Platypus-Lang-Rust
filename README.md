# FFI::Platypus::Lang::Rust ![static](https://github.com/PerlFFI/FFI-Platypus-Lang-Rust/workflows/static/badge.svg) ![linux](https://github.com/PerlFFI/FFI-Platypus-Lang-Rust/workflows/linux/badge.svg)

Documentation and tools for using Platypus with the Rust programming language

# SYNOPSIS

Rust:

```
#![crate_type = "cdylib"]

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

# EXAMPLES

The examples in this discussion are bundled with this distribution and
can be found in the `examples` directory.

## Passing and Returning Integers

### Rust Source

```
#![crate_type = "cdylib"]

#[no_mangle]
pub extern "C" fn add(a: i32, b: i32) -> i32 {
    a + b
}
```

### Perl Source

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

### Execute

```
$ rustc add.rs
$ perl add.pl
3
```

### Notes

Basic types like integers and floating points are the easiest to pass
across the FFI boundary.  The Platypus Rust language plugin (this module)
provides the basic types used by Rust (for example: `bool`, `i32`, `u64`,
`f64`, `isize` and others) will all work as a Rust programmer would expect.
This is nice because you don't have to think about what the equivalent types
would be in C when you are writing your Perl extension in Rust.

Rust symbols are "mangled" by default, which means that you cannot use
the name of the function from the source code without knowing what the
mangled name is.  Rust provides a function attribute `#[no_mangle]`
which will tell the compiler not to mangle the name, making lookup of
the symbol possible from other programming languages like Perl.

Rust functions do not use the same ABI as C by default, so if you want
to be able to call Rust functions from Perl they need to be declared
as `extern "C"` as in this example.

We also set the "crate type" to `cdylib` in the first line to tell the
Rust compiler to generate a dynamic library that will be consumed by
a non-Rust language like Perl.

## String Arguments

### Rust Source

```perl
#![crate_type = "cdylib"]

use std::ffi::CStr;

#[no_mangle]
pub extern "C" fn how_many_characters(s: *const i8) -> isize {
    if s.is_null() {
        return -1;
    }

    let s = unsafe { CStr::from_ptr(s) };

    match s.to_str() {
        Ok(s) => s.chars().count() as isize,
        Err(_) => -2,
    }
}
```

### Perl Source

```perl
use FFI::Platypus 2.00;
use FFI::CheckLib qw( find_lib_or_die );
use File::Basename qw( dirname );

my $ffi = FFI::Platypus->new( api => 2, lang => 'Rust' );
$ffi->lib(
    find_lib_or_die(
        lib        => 'argument',
        libpath    => [dirname __FILE__],
        systempath => [],
    )
);

$ffi->attach( how_many_characters => ['string'] => 'isize' );

print how_many_characters(undef), "\n";           # prints -1
print how_many_characters("frooble bits"), "\n";  # prints 12
```

### Execute

```
$ rustc argument.rs
$ perl argument.pl
-1
12
```

### Notes

Strings are considerably more complicated for a number of reasons,
but for passing them into Rust code the main challenge is that the
representation is different from what C uses.  C Uses NULL terminated
strings and Rust uses a pointer and size combination that allows
NULLs inside strings.  Perls internal representation of strings is
actually closer to what Rust uses, but when Perl talks to other
languages it typically uses C Strings.

Getting a Rust string slice `&str` requires a few stems

- We have to ensure the C pointer is not `NULL`

    We return `-1` to indicate an error here.  As we can see from the
    calling Perl code passing an `undef` from Perl is equivalent to
    passing in `NULL` from C.

- Wrap using `Cstr`

    We then wrap the pointer using an `unsafe` block.  Even though
    we know at this point that the pointer cannot be `NULL` it could
    technically be pointing to uninitialized or unaddressable memory.
    This `unsafe` block is unfortunately necessary, though it is
    relatively isolated so it is easy to reason about and review.

- Convert to UTF-8

    If the string that we passed in is valid UTF-8 we can convert
    it to a `&str` using `to_str` and compute the length of the
    string.  Otherwise, we return -2 error.

(This example is based on one provided in the
[Rust FFI Omnibus](http://jakegoulding.com/rust-ffi-omnibus/string_arguments/))

## Returning allocated strings

### Rust Source

```perl
#![crate_type = "cdylib"]

use std::ffi::CString;
use std::iter;

#[no_mangle]
pub extern "C" fn theme_song_generate(length: u8) -> *mut i8 {
    let mut song = String::from("💣 ");
    song.extend(iter::repeat("na ").take(length as usize));
    song.push_str("Batman! 💣");

    let c_str_song = CString::new(song).unwrap();
    c_str_song.into_raw()
}

#[no_mangle]
pub extern "C" fn theme_song_free(s: *mut i8) {
    if s.is_null() {
        return;
    }
    unsafe { CString::from_raw(s) };
}
```

### Perl Source

```perl
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
```

### Execute

```
$ rustc return.rs
$ perl return.pl
💣 na na na na na na na na na na na na na na na na na na na na na na na na na na na na na na na na na na na na na na na na na na Batman! 💣
```

### Notes

The big challenge of returning strings from Rust into Perl is
handling the ownership.  In this example we have a C API implemented
in Rust that returns a C NULL terminated string, but we have to
pass it back into Rust in order to deallocate it when we are done.

Unfortunately Platypus' `string` type assumes that the callee
retains ownership of the returned string, so we have to get the
pointer instead as an `opaque` so that we can later free it.
Before freeing it though we cast it into a Perl string.

In order to hide the complexities from caller of our
`theme_song_generate` function, we use a function wrapper to
do all of that for us.

(This example is based on one provided in the
[Rust FFI Omnibus](http://jakegoulding.com/rust-ffi-omnibus/string_return/))

## Returning allocated strings, but keeping ownership

### Rust Source

```perl
#![crate_type = "cdylib"]

use std::cell::RefCell;
use std::ffi::CString;
use std::iter;

#[no_mangle]
pub extern "C" fn theme_song_generate(length: u8) -> *const i8 {

    thread_local! {
        static KEEP: RefCell<Option<CString>> = RefCell::new(None);
    }

    let mut song = String::from("💣 ");
    song.extend(iter::repeat("na ").take(length as usize));
    song.push_str("Batman! 💣");

    let c_str_song = CString::new(song).unwrap();

    let ptr = c_str_song.as_ptr();

    KEEP.with(|k| {
        *k.borrow_mut() = Some(c_str_song);
    });

    ptr
}
```

### Perl Source

```perl
use FFI::Platypus 2.00;
use FFI::CheckLib qw( find_lib_or_die );
use File::Basename qw( dirname );

my $ffi = FFI::Platypus->new( api => 2, lang => 'Rust' );
$ffi->lib(
    find_lib_or_die(
        lib        => 'keep',
        libpath    => [dirname __FILE__],
        systempath => [],
    )
);

$ffi->attach( theme_song_generate => ['u8'] => 'string' );

print theme_song_generate($_), "\n" for 1..10;
```

### Execute

```
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
```

### Notes

For frequently called functions with smaller strings it may make more
sense to keep ownership of the string and just return a pointer.  Perl
makes its own copy on return anyway when you use the `string` type.

In this example we use thread local storage to keep the `CString`
until the next call when it will be freed.  Since we are using thread
local storage, it should even be safe to use this interface from a
threaded Perl program (although you should probably not be using
threaded Perl).

(This example is based on one provided in the
[Rust FFI Omnibus](http://jakegoulding.com/rust-ffi-omnibus/string_arguments/))

# ADVANCED

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

## callbacks

Calling back into Perl from Rust is easy so long as you have the correct
types defined.  Consider a Rust function that takes a C function pointer:

```perl
#![crate_type = "cdylib"]

use std::ffi::CString;

// compile with: rustc callback.rs

type PerlLog = extern "C" fn(line: *const i8);

#[no_mangle]
pub extern "C" fn rust_log(logf: PerlLog) {
    let lines: [&str; 3] = ["Hello from rust!", "Something else.", "The last log line"];

    for line in lines.iter() {
        // convert string slice to a C style NULL terminated string
        let line = CString::new(*line).unwrap();
        logf(line.as_ptr());
    }
}
```

This can be called with a closure from Perl:

```perl
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

- [The Rust FFI Omnibus](http://jakegoulding.com/rust-ffi-omnibus/)

    Includes a number of examples of calling Rust from other languages.

- [The Rustonomicon - Foreign Function Interface](https://doc.rust-lang.org/nomicon/ffi.html)

    Detailed Rust documentation on crossing the FFI barrier.

# AUTHOR

Author: Graham Ollis <plicease@cpan.org>

Contributors:

Andrew Grangaard (SPAZM)

# COPYRIGHT AND LICENSE

This software is copyright (c) 2015-2022 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
