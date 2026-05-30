// Spec test: Section 20b — implicit integer narrowing / sign conversion are
// denied (require an explicit `as`). The error cases live in
// test/compile_errors/err_implicit_narrowing.w and err_sign_conversion.w.

// PASS: widening is lossless and implicit.
fn test_widening:
    let small: i32 = 42
    let big: i64 = small
    assert(big == 42)

// PASS: explicit narrowing cast.
fn test_explicit_narrowing:
    let big: i64 = 300
    let small: i32 = big as i32
    assert(small == 300)

// PASS: explicit sign conversion.
fn test_explicit_sign:
    let x: i32 = 42
    let y: u32 = x as u32
    assert(y == 42)

// PASS: integer literals adapt to the annotated width.
fn test_literal_adapt:
    let a: i32 = 42
    let b: i64 = 42
    let c: u8 = 200
    assert(a == 42)
    assert(b == 42)
    assert(c == 200)
