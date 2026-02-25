fn main() -> i32 =
    var sum: i32 = 0
    for i in 3..10:
        sum += i
    assert(sum == 42)
    0
