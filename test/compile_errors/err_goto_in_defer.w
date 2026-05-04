//! expect-check-fail: goto not allowed in defer

fn main:
    defer: goto 'done
    'done return
