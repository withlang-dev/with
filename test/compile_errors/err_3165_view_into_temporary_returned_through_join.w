//! expect-check-fail: returns a view into a temporary `str` that is freed when this statement ends
// #3165, §21.1: a join of a view into a statement temporary is a view into
// it (#962's carrier rule); returned as a view, it would name freed memory.
use std.string

fn tail(why: &str, k: i32) -> &str:
    if k < 0: why.trim() else: why.slice(2, why.len()).trim()

fn main:
    print(tail("x, stored", 1))
