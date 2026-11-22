//! expect-error: wrong argument type in call to 'str.slice'
// #2023: Sema checks a str intrinsic's index arguments; a str where
// slice takes an i64 is refused here, not left to codegen.
fn main:
    print("abc".slice("x", 2))
