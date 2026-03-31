//! expect-stdout: ok

fn main:
    let ints: Vec[i32] = Vec.new()
    ints.push(1)
    ints.push(2)
    assert(ints.contains(1))
    assert(ints.contains(2))
    assert(not ints.contains(3))

    let strs: Vec[str] = Vec.new()
    strs.push("alpha")
    strs.push("beta")
    assert(strs.contains("alpha"))
    assert(strs.contains("beta"))
    assert(not strs.contains("gamma"))

    print("ok")
