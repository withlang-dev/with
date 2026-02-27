// POSITIVE: i32 is a Copy type — assignment copies, both values accessible (§2.3)
fn main -> i32:
    let a: i32 = 42
    let b: i32 = a
    assert(a == 42)
    assert(b == 42)
    println("copy survives ok")
