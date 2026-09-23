//! expect-stdout: ok

// §12.4: "Captures are by place regardless of whether the type is Copy; a
// read through a capture of a Copy value copies it. `move ||` transfers
// ownership, which for a Copy value is a copy." A non-move closure that
// assigns a captured `i32` writes the OUTER place; a `move` closure writes
// its own copy and the outer binding is unchanged. Non-Copy captures are
// by place the same way (`values.push` mutates the original).

fn call_value(f: fn() -> i32) -> i32:
    f()

fn main:
    var n = 10
    let direct_result = call_value(() =>
        n = n + 1
        n
    )
    assert(direct_result == 11)
    assert(n == 11)

    var m = 10
    let moved_result = call_value(move () =>
        m = m + 1
        m
    )
    assert(moved_result == 11)
    assert(m == 10)

    var values: Vec[i32] = Vec.new()
    values.push(1)
    var offset = 4
    let mixed_result = call_value(() =>
        values.push(offset)
        offset = offset + 10
        values.len32() + offset
    )
    assert(mixed_result == 16)
    assert(offset == 14)
    assert(values.len32() == 2)
    assert(values[1] == 4)

    var count = 0
    let bump = () => count += 1
    bump()
    bump()
    assert(count == 2)

    print("ok")
