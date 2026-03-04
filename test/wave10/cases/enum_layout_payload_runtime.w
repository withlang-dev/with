type Value = Num(i32) | Text(str) | Nil

fn main -> i32:
    let n = Num(7)
    assert(n.is_Num())
    let n_opt = n.as_Num()
    assert(n_opt.is_some())
    assert(n_opt.unwrap() == 7)

    let t = Text("abc")
    assert(t.is_Text())
    assert(not t.is_Num())
    assert(t.as_Num().is_none())

    let z: Value = Nil
    assert(z.is_Nil())
