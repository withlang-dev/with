//! expect-stdout: false

// #1626: casting a `&Unit` through `*const Unit` to `*mut c_void` lowers
// (a zero-sized pointee has no size to ask LLVM for).
fn main:
    let u = ()
    let p = (&u) as *const Unit as *mut c_void
    print(p == null)
