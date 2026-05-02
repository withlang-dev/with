//! expect-check-fail: closure that mutates captured place cannot escape its defining scope

fn main:
    var x = 10
    let f = () =>
        x = x + 1
        x
    let result = f()
