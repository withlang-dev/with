//! expect-stdout: ok 3 42
// #565 (§4.2.4): pipeline syntax is method-call sugar in comptime too — a
// primitive intrinsic reached through |> evaluates like the direct method
// form. Top-level comptime initializers are folded by the transform pass
// before sema types them, so the evaluator resolves the sugar itself.
comptime fn double(x: i32) -> i32: x * 2

const PIPE_ROT: u8 = comptime ((0b10000001 as u8) |> rotate_left(1))
const DIRECT_ROT: u8 = comptime ((0b10000001 as u8).rotate_left(1))
const FREE_PIPE: i32 = comptime (21 |> double())

fn main:
    assert(PIPE_ROT == 0b00000011 as u8)
    assert(PIPE_ROT == DIRECT_ROT)
    print(f"ok {PIPE_ROT} {FREE_PIPE}")
