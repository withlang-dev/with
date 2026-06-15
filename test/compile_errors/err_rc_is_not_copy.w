//! expect-check-fail: use of moved value

fn main:
    let rc = Rc.new(41)
    let _moved = rc
    let _use_after_move = rc
