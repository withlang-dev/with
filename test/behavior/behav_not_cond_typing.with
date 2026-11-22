//! expect-stdout: ok

// `not`/negate/bit-not results in condition position must carry their real
// types in MIR. The regression typed `unop(not, …)` temps as Unit (the
// typed_expr_types sidecar does not record unary nodes and the fallback had
// no unary cases), producing switchInt-on-Unit — flagged by audit:returns.

fn guard(flag: bool) -> i32:
    if not flag:
        return 1
    0

fn main:
    if not false:
        if guard(false) != 1: print("bad guard-false")
    if guard(true) != 0: print("bad guard-true")
    let n = -3
    if not (n > 0):
        var m: i32 = 0
        m = ~m
        if not (m == 0):
            print("ok")
