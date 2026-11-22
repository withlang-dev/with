//! expect-stdout: ok

// Test: for-loop iteration over List[i32].

fn main:
    let v: List[i32] = List.new()
    v.push(10)
    v.push(20)
    v.push(30)

    var total = 0
    for x in v:
        total = total + x

    assert(total == 60)
    print("ok")
