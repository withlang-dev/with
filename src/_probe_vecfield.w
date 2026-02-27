type A = {
    v: Vec[i32],
}

fn f(a: A) -> void:
    a.v.push(1)

fn main:
    var a = A { v: Vec.new() }
    f(a)
    println(i32_to_str(a.v.len() as i32))

extern fn i32_to_str(n: i32) -> str
