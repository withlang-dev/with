fn main -> i32:
    var x: i32 = 1
    let m = &mut x
    *m = 3
    let r = &x
    *r
