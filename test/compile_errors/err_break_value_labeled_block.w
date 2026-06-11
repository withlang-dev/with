//! expect-check-fail: break with a value is only valid for `loop`

fn main:
    'blk:
        break 'blk 1
