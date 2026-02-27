extern fn putchar(c: i32) -> i32

fn main -> i32:
    var i: i32 = 0
    var sum: i32 = 0
    while i < 100:
        i += 1
        if i == 3 then continue
        if i == 6 then break
        sum += i
    assert(sum == 12)
