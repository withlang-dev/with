//! expect-check-fail: break with a value is not supported

fn main:
    'outer while true:
        break 'outer 1
