//! expect-check-fail: binds a view into a temporary `str` that is freed when this statement ends

// #2225 (§21.1, #962 for a callee): `trim()` views its receiver, and the
// receiver here is the owned str `slice` returns — a statement temporary.
// A binding of the view read freed memory (the compiler's own import
// reader did exactly this); it is refused like `temp()[i]` is.
fn main:
    let s = "hello world"
    let a = s.slice(0, 5).trim()
    print(a)
