//! expect-stdout: ok

fn main:
    var empty: Vec[i32] = Vec.new()
    assert(empty.pop().is_none())
    assert(empty.len() == 0)

    var v: Vec[i32] = Vec.new()
    let popped = v |> push(20) |> push(22) |> pop()
    assert(popped.unwrap() == 22)
    assert(v.len() == 1)
    assert(v[0] == 20)

    let from_temporary: Option[i32] = Vec[i32].new() |> push(42) |> pop()
    assert(from_temporary.unwrap() == 42)
    print("ok")
