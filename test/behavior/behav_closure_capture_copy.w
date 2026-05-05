// Non-move closure captures Copy type by copy; original unchanged after closure mutates its copy.

fn apply(f: fn(i32) -> i32, x: i32) -> i32: f(x)

fn main:
    var n = 10
    // Non-move escaping closure captures i32 (Copy) — gets its own copy.
    let result = apply(
        (x: i32) =>
            n + x   // reads closure's copy of n
        , 5)
    assert(result == 15)
    assert(n == 10)   // original n unchanged
    print("ok\n")
