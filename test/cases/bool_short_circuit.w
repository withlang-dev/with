// Test boolean short-circuit evaluation
fn main() -> i32 =
    // 'and' short-circuits: false and X => false
    let a = false and true
    assert(not a)
    // 'or' short-circuits: true or X => true
    let b = true or false
    assert(b)
    // Normal evaluation
    let c = true and true
    assert(c)
    let d = false or false
    assert(not d)
    let e = true and false
    assert(not e)
    let f = false or true
    assert(f)
    println("all short circuit tests passed")
    0
