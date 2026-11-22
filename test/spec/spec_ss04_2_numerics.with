// Spec test: Section 4.2 — Numerics (formerly 25.19)

// PASS: wrapping arithmetic
fn test_wrapping_add:
    let x: u8 = 255
    assert(x +% 1 == 0)

// PASS: implicit widening
fn test_implicit_widening:
    let x: i32 = 42
    let y: i64 = x
    assert(y == 42)

// FAIL: overflow panics in debug — needs runtime panic test
// fn test_overflow_panics:
//     let x: u8 = 255
//     let y = x + 1   // panic in debug mode

// FAIL: implicit narrowing — needs expect-error test
// fn test_implicit_narrowing_rejected:
//     let x: i64 = 42
//     let y: i32 = x   // ERROR: implicit narrowing
