//! expect-stdout: ok

// Test: for-loop iteration over Vec[i32].

fn main:
    let v: Vec[i32] = Vec.new()
    v.push(10)
    v.push(20)
    v.push(30)

    var total = 0
    for x in v:
        total = total + x

    assert(total == 60)
    print("ok")
