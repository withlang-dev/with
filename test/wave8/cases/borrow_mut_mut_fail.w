fn main -> i32:
    var x: i32 = 1
    let m1 = &mut x
    let m2 = &mut x
    *m1 + *m2
