gen fn count_up(n: i32) -> i32 =
    var i: i32 = 0
    while i < n:
        yield i
        i += 1

fn main() -> i32 =
    var iter = count_up(5)
    var sum: i32 = 0
    for x in iter:
        sum += x
    assert(sum == 10)
    0
