//! skip
// Spec test: Section 16.1 — FFI Direct Call (formerly 25.88)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// PASS: c_import functions callable directly
use c_import("stdio.h")
fn test: puts(c"hello".ptr)      // no unsafe needed

// PASS: unsafe still required for pointer deref
fn test:
    let p: *mut i32 = alloc(4)
    unsafe { *p = 42 }               // pointer deref needs unsafe
    free(p)                           // C function call: no unsafe
