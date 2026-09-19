//! expect-stdout: ok 42 ok 84

// #1196: a function with no return annotation takes its type from its body
// (§9.1). A caller declared above it used to see no type at all. Every caller
// here has a written return type or a fixed contract (main), so declaration
// order must not matter.

type Counter { n: i32 }

impl Counter:
    fn positive() -> bool: self.n > 0 and later_pred()

fn go(x: i32) -> bool: x > 0 and later_pred()

// Neither function is annotated and the callee comes second, but the call is
// a statement: its value is discarded, so there is nothing to have got wrong
// (std/crypto/bigint.w calls i31_reduce_once this way).
fn bump_twice(n: i32):
    var calls = 0
    later(n)
    calls = calls + 1
    later(n)
    calls = calls + 1

fn main:
    let c = Counter { n: 1 }
    let n: i32 = later(2)
    let a = if c.positive(): "ok" else: "no"
    let b = if go(1): "ok" else: "no"
    let t: i32 = twice(2)
    print(f"{a} {n} {b} {t}")

// Unannotated calling unannotated, declared after it: `later` is typed first.
fn twice(x: i32): later(x) + later(x)

fn later_pred(): 1 + 1 == 2

fn later(x: i32): x * 21
