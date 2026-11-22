//! expect-check-fail: pass a named variable

// #604: a temporary collection cannot back a slice view argument — it would
// be freed while the callee still uses it.

use std.builtins.print_i32
fn total(xs: []i32) -> i32:
    xs[0]

fn make() -> List[i32]:
    let v: List[i32] = List.new()
    v.push(1)
    v

fn main:
    let n = total(make())
    print_i32(n)
