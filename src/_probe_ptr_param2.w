fn append1(v: *mut Vec[i32]) -> void:
    Vec.push(v, 1)

fn main:
    var v = Vec.new()
    append1(v)
    println(i32_to_str(v.len() as i32))

extern fn i32_to_str(n: i32) -> str
