// T2-3/T10 negative control: closure mutably captures `total` while a
// sibling arg retains access to it (check_closure_capture_conflicts :23959,
// §15.7). Expect check FAIL.
use std.builtins.int_to_string

fn apply(a: i32, f: fn(i32) -> i32) -> i32: f(a)

fn main:
    var total = 0
    let r = apply(total, x => total = total + x)
    print(int_to_string(r))
