fn main -> i32:
    var x: i32 = 42
    let r = &x
    assert(*r == 42)
