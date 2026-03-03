fn main -> i32:
    var x: i32 = 1
    let r = &x
    let m = &mut x
    let _v = *r
    *m = 2
    x
