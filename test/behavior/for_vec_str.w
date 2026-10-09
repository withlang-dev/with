//! expect-stdout: ok

// Test: for-loop iteration over List[str].

fn main:
    let v: List[str] = List.new()
    v.push("hello")
    v.push("world")

    var count = 0
    for s in v:
        count = count + 1

    assert(count == 2)
    print("ok")
