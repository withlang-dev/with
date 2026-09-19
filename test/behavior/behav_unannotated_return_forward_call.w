//! expect-stdout: ok 42 ok

// #1196: a function with no return annotation takes its type from its body
// (§9.1). A caller declared above it used to see no type at all. Every caller
// here has a written return type or a fixed contract (main), so declaration
// order must not matter.

type Counter { n: i32 }

impl Counter:
    fn positive() -> bool: self.n > 0 and later_pred()

fn go(x: i32) -> bool: x > 0 and later_pred()

fn main:
    let c = Counter { n: 1 }
    let n: i32 = later(2)
    let a = if c.positive(): "ok" else: "no"
    let b = if go(1): "ok" else: "no"
    print(f"{a} {n} {b}")

fn later_pred(): 1 + 1 == 2

fn later(x: i32): x * 21
