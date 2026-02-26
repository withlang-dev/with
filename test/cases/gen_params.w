gen fn range(start: i32, stop: i32) -> i32:
    var i: i32 = start
    while i < stop:
        yield i
        i += 1

fn main -> i32:
    var sum: i32 = 0
    var iter = range(3, 8)
    for x in iter:
        sum += x
    assert(sum == 25)
