//! expect-stdout: ok

// Behavior test: closure capture semantics
// Tests: capture single var, multiple vars, nested captures

fn apply(f: fn(i32) -> i32, x: i32) -> i32:
    f(x)

fn main:
    // Capture single variable
    let a = 10
    let r1 = apply(x => x + a, 5)
    assert(r1 == 15)

    // Capture multiple variables
    let b = 20
    let r2 = apply(x => x + a + b, 5)
    assert(r2 == 35)

    // Captured let binding retains value across calls
    let factor = 3
    let r3 = apply(x => x * factor, 4)
    assert(r3 == 12)
    let r4 = apply(x => x * factor, 7)
    assert(r4 == 21)

    // Capture with larger offsets
    let base = 100
    let offset = 50
    let r5 = apply(x => x + base + offset, 1)
    assert(r5 == 151)

    // Closure that ignores its parameter
    let constant = 42
    let r6 = apply(x => constant, 999)
    assert(r6 == 42)

    println("ok")
