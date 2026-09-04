//! expect-error: integer overflow in comptime

// #943: pins the current (wrong) diagnostic. Both operands are i64 and the
// declared return type is i64, so this is in range and must evaluate to
// 2147483648 — but the comptime evaluator does the arithmetic at 32 bits and
// reports an overflow that does not exist.
//
// When #943 is fixed this file stops erroring and goes red. That is intended:
// the red is the signal to move the case into behav_comptime_int_width.w as a
// passing assertion and delete this file.

comptime fn edge -> i64:
    2147483647i64 + 1i64

const E: i64 = comptime edge()

fn main:
    print(f"{E}")
