//! expect-stdout: ok

// Behavior test: closures
// Tests: basic closure syntax, calling closures, passing as arguments

fn apply(f: fn(i32) -> i32, x: i32) -> i32:
    f(x)

fn double(x: i32) -> i32:
    x * 2

fn main:
    // Named function as argument
    let r1 = apply(double, 5)
    assert(r1 == 10)

    // Inline closure
    let r2 = apply(x => x + 1, 10)
    assert(r2 == 11)

    // Closure with multiply
    let r3 = apply(x => x * 3, 7)
    assert(r3 == 21)

    // Closure capturing outer variable
    let offset = 100
    let r4 = apply(x => x + offset, 5)
    assert(r4 == 105)

    // Closure with multiple captures
    let a = 10
    let b = 20
    let r5 = apply(x => x + a + b, 5)
    assert(r5 == 35)

    // Apply twice
    let r6 = apply(double, apply(double, 3))
    assert(r6 == 12)

    println("ok")
