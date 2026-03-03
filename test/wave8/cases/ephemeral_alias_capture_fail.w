fn main -> i32:
    var x: i32 = 1
    let r = &x
    let rr = r
    let f = || *rr
    f()
