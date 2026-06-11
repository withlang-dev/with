//! expect-check-fail: break values of this loop do not unify

fn main:
    let flag = true
    let _ = loop:
        if flag:
            break 1
        break
