// Test comptime arithmetic evaluation
fn main -> i32:
    let a = comptime 3 + 4 * 2
    println(a)

    let b = comptime (10 - 3) * 2
    println(b)

    let c = comptime if 5 > 3 then 100 else 200
    println(c)
