pub fn sum_pair(a: i32, b: i32) -> i32:
    let xs: List[i32] = List.new()
    xs.push(a)
    xs.push(b)
    xs[0] + xs[1]
