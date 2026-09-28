//! expect-stdout: 42
//! expect-stdout: 7

// A type in expression position — the type argument of `transmute[T](x)` —
// inside a closure body. The capture analysis walks the closure's body
// (SemaCheck.w expr_uses_symbol) and met the type argument the callee's
// index carries: `internal error: expr_uses_symbol has no case for node
// kind 127` (NK_TYPE_EXTERN_FN), and for a pointer type argument its kind
// likewise. A type names no value, so it captures nothing; the closure
// still captures the pointer it transmutes.
fn double(n: i32) -> i32: n * 2

fn main:
    let f: extern "C" fn(i32) -> i32 = double
    let p = unsafe { transmute[*mut c_void](f) }
    let call: fn(i32) -> i32 = n => {
        let g: extern "C" fn(i32) -> i32 = unsafe { transmute[extern "C" fn(i32) -> i32](p) }
        g(n)
    }
    print(f"{call(21)}")
    let x: i64 = 7
    let widen: fn() -> i64 = () => {
        let q = unsafe { transmute[*const i64](&raw const x) }
        unsafe { *q }
    }
    print(f"{widen()}")
