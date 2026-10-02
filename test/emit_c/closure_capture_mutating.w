//! expect-stdout: 2
//! expect-stdout: 11 11
//! expect-stdout: 2 4 14

// #1766, D62 (§12.4): a non-move closure that assigns a captured value
// writes the OUTER place, Copy or not; a `move` closure writes its own copy.
fn call_value(f: fn() -> i32) -> i32: f()

fn main:
    var count = 0
    let bump = () => count += 1
    bump()
    bump()
    print(count)
    var n = 10
    let direct = call_value(() =>
        n = n + 1
        n
    )
    print(f"{direct} {n}")
    var values: Vec[i32] = Vec.new()
    values.push(1)
    var offset = 4
    let mixed = call_value(() =>
        values.push(offset)
        offset = offset + 10
        values.len32() + offset
    )
    print(f"{values.len32()} {values[1]} {offset}")
    let _ = mixed
