//! expect-check-fail: closure that mutates captured place cannot escape its defining scope

fn main:
    var x: Vec[i32] = Vec.new()
    let f = () =>
        x.push(1)
        x.len32()
    let result = f()
