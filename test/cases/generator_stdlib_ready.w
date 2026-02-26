// Test: generator lowering integration with stdlib collection/math APIs
use std.collections
use std.math

gen fn squares(n: i32) -> i32:
    var i: i32 = 0
    while i < n:
        yield i * i
        i += 1

fn main -> i32:
    var iter = squares(5)
    var vals: Vec[i32] = Vec.new()
    for x in iter:
        vals.push(abs(x))

    assert(vals.len() == 5)
    assert(vals.get(0) == 0)
    assert(vals.get(1) == 1)
    assert(vals.get(4) == 16)

    var grouped: HashMap[str, Vec[i32]] = HashMap.new()
    append(grouped, "sq", vals.get(1))
    append(grouped, "sq", vals.get(2))
    let got = grouped.get("sq").unwrap()
    assert(got.len() == 2)
    assert(got.get(0) == 1)
    assert(got.get(1) == 4)

