//! expect-stdout: 3 6 4
//! expect-stdout: ok

// §4.9a (D103) at compile time: a `T` tail under a `-> Option[T]` return is
// `Some(value)` — Sema's `value_to_option_nodes` fact, applied by the
// evaluator exactly as MIR lowering applies it — in a free function and in a
// user iterator's `next`, reached from a `const` before the body pass runs.

fn wrap(x: i32) -> Option[i32]: x

comptime fn pick() -> i32:
    match wrap(3):
        Some(v) => v
        None => -1

type Up ephemeral { n: i32, at: i32 }
impl Iter[i32] for Up:
    mut fn next() -> Option[i32]:
        if self.at >= self.n: return None
        let b = self.at
        self.at += 1
        b

comptime fn total(n: i32) -> i32:
    var acc = 0
    let up = Up { n, at: 0 }
    for x in up: acc += x
    acc

// A user-written `Some(x)` and a wrapped one are the same variant to
// `match`, `is_some()` and `??` alike.
comptime fn probe() -> i32:
    let o: Option[i32] = Some(3)
    var n = 0
    if o.is_some(): n += 1
    n += o ?? 10
    n

const V: i32 = comptime pick()
const T: i32 = comptime total(4)
const P: i32 = comptime probe()

fn main:
    print(f"{V} {T} {P}")
    print("ok")
