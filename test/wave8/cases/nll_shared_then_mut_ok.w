fn main -> i32:
    var x: i32 = 1
    let r = &x
    let _v = *r
    let m = &mut x
    *m = 2
    x
