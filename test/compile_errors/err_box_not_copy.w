//! expect-check-fail: use of moved value

fn main:
    let b = Box.new(41)
    let _moved = b
    let _use_after_move = b
