//! expect-check-fail: label cannot cross function, closure, or async boundary

fn main:
    var flag = true
    'outer while flag:
        async:
            break 'outer
        flag = false
