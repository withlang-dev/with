type Box = { x: i32 }

fn mutate_box(b: *mut Box) -> void:
    b.x = 9

fn main:
    var b = Box { x: 0 }
    mutate_box(b)
    println(i32_to_str(b.x))

extern fn i32_to_str(n: i32) -> str
