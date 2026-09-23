//! expect-check-fail: return type mismatch

// §9.1 / §4.10 / D60: the block spelling of err_d60_tail_mismatch.w — the
// body block's tail assignment is its value, and a bool place does not
// match `-> i32`.

var flag: bool = false
fn f -> i32:
    let v = true
    flag = v

fn main: print(f())
