fn main:
    let v: Vec[str] = Vec.new() |> push("a") |> push("b")
    assert(v.len() == 2)
    assert(v[0] == "a")
    assert(v[1] == "b")

    var w: Vec[i32] = Vec.new()
    w |> push(10)
    w |> push(20)
    assert(w.len() == 2)
    assert(w[0] == 10)
    assert(w[1] == 20)

    print("ok")
