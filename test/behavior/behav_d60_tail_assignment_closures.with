//! expect-stdout: typed 1 2
//! expect-stdout: block 24
//! expect-stdout: argument 99
//! expect-stdout: arms 5 6
//! expect-stdout: untyped 7
//! expect-stdout: unit 8

// §9.1 / D60: a closure's expected function type is its declared return. A
// closure body under `fn(..) -> T`, T not `Unit`, yields a read of the
// assigned place — as a single expression, a block tail, or an arm. With no
// expected result (D43) or `-> Unit` the tail assignment is a statement.

var n: i32 = 0

fn run_i32(f: fn() -> i32) -> i32: f()
fn run_unit(f: fn() -> Unit): f()

fn main:
    let typed: fn() -> i32 = () => n += 1
    let t1 = typed()
    print(f"typed {t1} {typed()}")
    let block_typed: fn() -> i32 = () =>
        n += 10
        n *= 2
    print(f"block {block_typed()}")
    print(f"argument {run_i32(() => n = 99)}")
    let pick: fn(bool) -> i32 = (p: bool) => if p: n = 5 else: n = 6
    let a = pick(true)
    print(f"arms {a} {pick(false)}")
    let untyped = () => n += 1
    untyped()
    print(f"untyped {n}")
    run_unit(() => n += 1)
    print(f"unit {n}")
