fn main -> i32:
    var x: i32 = 1
    let a = &x
    let b = &mut x
    *a + *b
