// T08 probe: comptime int equality across widths (type-identity sensitivity).
comptime fn cross_width_eq() -> bool:
    let a: i32 = 1
    let b: i64 = 1
    a == b

fn main:
    assert(comptime cross_width_eq())
    print("ok")
