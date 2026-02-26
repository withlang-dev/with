fn main -> i32:
    let x: Option[i32] = None
    assert(x ?? 42 == 42)
