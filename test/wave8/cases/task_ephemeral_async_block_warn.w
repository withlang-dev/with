fn sink(t: i32) -> i32:
    t

fn main -> i32:
    let mut x = 3
    let r = &mut x
    let t = async: *r
    sink(t)
    0
