//! expect-stdout: ok

// §16.5: a @[c_export] function with a C-ABI-expressible signature — scalars,
// raw pointers, and @[repr(C)] aggregates — is accepted.

@[repr(C)]
type Config { width: i32, height: i32 }

@[c_export("lib_area")]
unsafe fn lib_area(c: *const Config) -> i32:
    (*c).width * (*c).height

@[c_export("lib_add")]
fn lib_add(a: i32, b: i32) -> i32:
    a + b

fn main:
    var cfg = Config { width: 4, height: 5 }
    unsafe:
        if lib_area(&raw const cfg) == 20 and lib_add(2, 3) == 5:
            print("ok")
        else:
            print("bad")
