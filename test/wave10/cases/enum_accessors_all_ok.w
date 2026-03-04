type Value = Num(i32) | Text(str) | Nil

fn main -> i32:
    let n = Num(10)
    assert(n.is_Num())
    assert(not n.is_Text())
    assert(not n.is_Nil())

    let n_by_val = n.as_Num()
    assert(n_by_val.is_some())
    assert(n_by_val.unwrap() == 10)

    let n_by_ref = n.as_Num_ref()
    let n_by_mut = n.as_Num_mut()
    assert(n_by_ref.is_some())
    assert(n_by_mut.is_some())

    let t = Text("hello")
    assert(t.as_Num().is_none())
    assert(t.as_Num_ref().is_none())
    assert(t.as_Num_mut().is_none())

    let u: Value = Nil
    assert(u.is_Nil())
