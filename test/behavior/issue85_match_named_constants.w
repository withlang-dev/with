//! expect-stdout: ok

let OP_STAR: i32 = 42
let OP_PLUS: i32 = 43

enum Opcode: i32 { Star = 42 | Plus = 43 | End = 99 }

fn match_named_constant(opcode: i32) -> i32:
    match opcode
        OP_STAR => 1
        OP_PLUS => 2
        _ => 0

fn match_qualified_discriminant(opcode: i32) -> i32:
    match opcode
        Opcode.Star => 10
        Opcode.Plus => 20
        _ => 0

fn main:
    assert(match_named_constant(42) == 1)
    assert(match_named_constant(43) == 2)
    assert(match_named_constant(99) == 0)

    assert(match_qualified_discriminant(42) == 10)
    assert(match_qualified_discriminant(43) == 20)
    assert(match_qualified_discriminant(99) == 0)

    print("ok")
