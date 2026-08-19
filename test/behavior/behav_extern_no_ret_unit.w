//! expect-stdout: ok

// An `extern fn` with no return annotation returns Unit — not TY_ERR. The
// regression left the MIR call destination untyped (ownership validator:
// "terminator place has no concrete MIR type") while codegen happened to
// tolerate it. Declaring and calling one must check, validate, and run.

extern fn with_alloc(size: i64) -> *mut u8
extern fn with_free(ptr: *mut u8)

fn main:
    unsafe:
        let p = with_alloc(16)
        with_free(p)
    print("ok")
