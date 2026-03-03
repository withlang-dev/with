fn main -> i32:
    var x: i32 = 1
    let m = &mut x
    let r = &x
    *m + *r
