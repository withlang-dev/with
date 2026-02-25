extern fn putchar(c: i32) -> i32

fn main() -> i32 =
    var i: i32 = 0
    while i < 5:
        putchar(48 + i)
        i = i + 1
    putchar(10)
    0
