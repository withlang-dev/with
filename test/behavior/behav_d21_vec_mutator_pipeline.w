//! expect-stdout: ok

fn accepts_unit(_value: Unit):
    let _ = _value

fn main:
    var v: Vec[i32] = Vec.new()
    accepts_unit(v.push(1))
    v |> push(2) |> clear() |> push(40) |> push(2)
    assert(v.len() == 2)
    assert(v[0] == 40)
    assert(v[1] == 2)

    v.push(v[0])
    v |> push(v[0])
    assert(v.len() == 4)
    assert(v[2] == 40)
    assert(v[3] == 40)

    let built: Vec[i32] = Vec.new() |> push(20) |> push(22)
    assert(built.len() == 2)
    assert(built[0] + built[1] == 42)
    print("ok")
