//! expect-stdout: 1 5 7 -1 42 9

use std.collections.HashMap

// D114 (§4.2.1): a literal-only `if` nested in a join with an `i32` arm is
// typed i32 once the join decides, the literal under `&` in `?? &-1` views
// the payload's type, and `isize` and `usize` have `to_string`.
fn take(x: i32): x

fn sig_of(m: &HashMap[i32, i32], k: i32) -> i32: m.get(k) ?? &-1

fn main:
    var m: HashMap[i32, i32] = HashMap.new()
    m.insert(3, 7)
    let n: i32 = 0
    let five: i32 = 5
    let has = true
    let first = if n > 0: n else: if has: 1 else: 0
    let second = if five > 0: five else: if has: 1 else: 0
    let wide: isize = 42
    let size: usize = 9
    print(f"{take(first)} {take(second)} {sig_of(&m, 3)} {sig_of(&m, 4)} {wide.to_string()} {size.to_string()}")
