type Box = { x: i32 }

fn Box.mutate(self: *mut Box) -> void:
    self.x = 42

fn main:
    var b = Box { x: 0 }
    Box.mutate(b)
    println(i32_to_str(b.x))

extern fn i32_to_str(n: i32) -> str
