gen fn fibonacci() -> i32 =
    var a: i32 = 0
    var b: i32 = 1
    loop:
        yield a
        let next = a + b
        a = b
        b = next

fn main() -> i32 =
    var iter = fibonacci()
    var sum: i32 = 0
    var count: i32 = 0
    for x in iter:
        sum += x
        count += 1
        if count == 7 then break
    assert(sum == 20)
    0
