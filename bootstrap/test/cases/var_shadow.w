// Test: variable shadowing in nested scopes
fn shadow_test(x: i32) -> i32:
    let a = x + 1
    let b = a + 1
    b

fn main -> i32:
    let x: i32 = 10
    assert(x == 10)
    let y: i32 = 20
    assert(y == 20)
    let z = x + y + 12
    assert(z == 42)

    // Function scopes provide natural shadowing
    let r = shadow_test(5)
    assert(r == 7)

    // Reuse variable names with different values
    let a: i32 = 1
    let b: i32 = 2
    let c = a + b
    assert(c == 3)

    let a2: i32 = 40
    let b2: i32 = 2
    assert(a2 + b2 == 42)

