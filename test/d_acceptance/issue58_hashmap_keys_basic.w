//! expect-stdout: ok

fn main:
    let empty: HashMap[i32, str] = HashMap.new()
    assert(empty.keys() |> count() == 0)

    var m: HashMap[i32, str] = HashMap.new()
    m.insert(1, "a")
    m.insert(2, "b")
    m.insert(1, "updated")

    let ks = m.keys() |> map(it.clone()) |> collect[Vec]()
    assert(ks == [1, 2])
    print("ok")
