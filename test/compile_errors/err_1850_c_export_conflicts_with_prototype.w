//! expect-error: and C calls it through that declaration: one is variadic and the other is not

// #1850, §16.5: a `@[c_export]` definition whose C function type differs
// from a declaration of the same symbol in scope is refused, naming both
// types. It linked against an undefined `__stale_decl` instead.
use c_import("int zz_sum(int n, ...);\n")

@[c_export("zz_sum")]
fn sum_impl(n: c_int, a: c_int, b: c_int) -> c_int: a + b

fn main:
    print(unsafe { zz_sum(2, 30, 12) })
