type B = { x: i32 }
fn B.set(self: *mut B) -> void:
    self.x = 7

type A = { b: B }

fn main:
    var a = A { b: B { x: 0 } }
    B.set(a.b)
    println(i32_to_str(a.b.x))

extern fn i32_to_str(n: i32) -> str
