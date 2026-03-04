type Value = Num(i32) | Text(str) | Nil

fn main -> i32:
    let v: Value = Nil
    let _bad = v.as_Nil()
