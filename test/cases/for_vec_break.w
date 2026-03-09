//! expect-stdout: ok

// Test: for-loop over Vec with break and continue.

fn main:
    let v: Vec[i32] = Vec.new()
    v.push(1)
    v.push(2)
    v.push(3)
    v.push(4)
    v.push(5)

    // Sum only odd values, stop at 4
    var total = 0
    for x in v:
        if x == 4:
            break
        if x % 2 == 0:
            continue
        total = total + x

    assert(total == 4)  // 1 + 3
    println("ok")
