fn main() -> i32 =
    let x = comptime 3 + 4
    println(x)
    let y = comptime if 10 > 5 then 1 else 0
    println(y)
    let z = comptime 2 * 3 + 1
    println(z)
    0
