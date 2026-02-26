fn main -> i32:
    var x: i32 = 10
    let r = &mut x
    *r = 42
    assert(x == 42)
