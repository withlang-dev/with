//! expect-stdout: ok

fn main:
    var values = Vec[i32].new()
    values.push(10)
    values.push(20)
    values.push(30)

    let before = values.get(1)
    values.set_i32(1, before + 1)

    assert(before == 20)
    assert(values.get(1) == 21)
    print("ok")
