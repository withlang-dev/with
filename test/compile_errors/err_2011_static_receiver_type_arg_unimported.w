//! expect-check-fail: 'Task' requires an explicit import (§18.1)
// #2011: a std type named inside a static call's receiver (`Vec[Task[i32]]`)
// needs its import exactly as in an annotation. Before, Sema accepted it and
// MIR lowering failed on the call ("MIR lowering failed for function").
async fn f(x: i32) -> i32: x

fn main:
    var xs = Vec[Task[i32]].new()
    xs.push(f(1))
