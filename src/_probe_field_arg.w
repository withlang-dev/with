type B = { x: i32 }
type A = { b: B }

fn setb(v: B) -> void:
    v.x = 7

fn main:
    var a = A { b: B { x: 0 } }
    setb(a.b)
    println(i32_to_str(a.b.x))

extern fn i32_to_str(n: i32) -> str
