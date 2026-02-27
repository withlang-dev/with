fn inc(x: i32) -> void:
    x = x + 1

fn main:
    var a = 0
    inc(a)
    println(i32_to_str(a))

extern fn i32_to_str(n: i32) -> str
