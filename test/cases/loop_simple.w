fn main() -> i32 =
    var i: i32 = 0
    loop:
        i += 1
        if i == 42 then break
    assert(i == 42)
    0
