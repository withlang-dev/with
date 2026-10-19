//! expect-stdout: 24 -7 0 12
//! expect-stdout: 2147483648

// #2460: std's parse/string_to_int is comptime-evaluable — it used to reach
// the extern with_parse_i64_ref, which the evaluator refused, so any build
// action (or const) that parsed a number failed during comptime evaluation
// (the windows SDK jobs' sdk-windows-libc, through build/par.w).
use std.string

const SLOTS = comptime parse("24")
const NEG = comptime parse("-7")
const EMPTY = comptime parse("")
const PREFIX = comptime parse("12x")
const BIG = comptime string_to_int("2147483648")

fn main:
    print(f"{SLOTS} {NEG} {EMPTY} {PREFIX}")
    print(BIG)
