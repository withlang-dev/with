//! expect-stdout: ok

// Comptime differential: unary operators — including deref/ref value
// identity through a reference param, the exact gap that broke every
// comptime-with build.w (718c8d61). Free fns because user methods are
// not comptime-evaluable yet (#665).

type Acc { total: i32 }
impl Copy for Acc

comptime fn bump(a: &Acc, n: i32) -> Acc:
    var out = *a
    out.total = out.total + n
    out

comptime fn unary_battery(n: i32) -> i32:
    let a = Acc { total: n }
    let b = bump(&a, 5)
    let c = bump(&b, 7)
    var acc = c.total
    acc = acc + (0 - n)
    if not (n == 0):
        acc = acc + 1000
    acc

const CT_UNARY: i32 = comptime unary_battery(21)

fn main:
    assert(CT_UNARY == unary_battery(21))
    print("ok")
