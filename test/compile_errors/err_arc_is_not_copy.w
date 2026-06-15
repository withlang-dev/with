//! expect-check-fail: use of moved value

fn main:
    let arc = Arc.new(41)
    let _moved = arc
    let _use_after_move = arc
