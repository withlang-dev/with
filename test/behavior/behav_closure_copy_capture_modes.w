//! expect-stdout: ok

fn call_value(f: fn() -> i32) -> i32:
    f()

fn main:
    var n = 10
    let direct_result = call_value(() =>
        n = n + 1
        n
    )
    assert(direct_result == 11)
    assert(n == 10)

    var values: Vec[i32] = Vec.new()
    values.push(1)
    var offset = 4
    let mixed_result = call_value(() =>
        values.push(offset)
        offset = offset + 10
        values.len32() + offset
    )
    assert(mixed_result == 16)
    assert(offset == 4)
    assert(values.len32() == 2)

    print("ok")
