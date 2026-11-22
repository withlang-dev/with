//! expect-check-fail: label cannot cross function, closure, or async boundary

fn main:
    var flag = true
    'outer while flag:
        let f = () => break 'outer
        flag = false
