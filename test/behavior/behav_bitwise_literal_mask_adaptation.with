//! expect-stdout: ok

// Bitwise masks written as (folded) negative or ~-wrapped literals adapt
// to the concrete operand type with bit-pattern validation (June rule +
// Ast.int_literal_exact_expr folded-negative fix).

fn align16(size: i64) -> i64: (size + 15) & (-16)
fn mask_p(size: i64) -> i64: size & (-16)
fn mask_b(size: i64) -> i64: size & -16
fn mask_u(flags: u32) -> u32: flags & (~1)
fn main:
    assert(align16(17) == 32)
    assert(mask_p(33) == 32)
    assert(mask_b(33) == 32)
    assert(mask_u(7) == 6)
    print("ok")
