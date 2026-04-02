pub fn sum(xs: Vec[i32]) -> i32:
    var acc: i32 = 0
    for pi in 0..xs.len():
        acc = acc + xs[pi]
    acc
