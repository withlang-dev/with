//! expect-stdout: ok

fn main:
    var values = Vec[i32].new()
    values.push(10)
    values.push(20)
    values.push(30)

    let before: i32 = values[1]
    values[1] = before + 1

    assert(before == 20)
    assert(values[1] == 21)
    print("ok")
