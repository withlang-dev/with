pub fn sum_pair(a: i32, b: i32) -> i32:
    let xs: Vec[i32] = Vec.new()
    xs.push(a)
    xs.push(b)
    xs.get(0) + xs.get(1)
