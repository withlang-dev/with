//! expect-stdout: ok

// Test: statement-position match allows partial patterns.
// Expression-position match with all variants covered works.

type Color = Red | Green | Blue

fn test_stmt_match_partial_int:
    let x = 1
    match x
        1 => println("one")
        _ => println("other")

fn test_expr_match_enum_exhaustive:
    let c: Color = .Red
    let v = match c
        .Red => 1
        .Green => 2
        .Blue => 3
    assert(v == 1)

fn test_stmt_match_enum_partial:
    // Partial match in statement position — only Red handled, no warning
    let c: Color = .Red
    match c
        .Red => println("red matched")

fn main:
    test_stmt_match_partial_int()
    test_expr_match_enum_exhaustive()
    test_stmt_match_enum_partial()
    println("ok")
