// Test: Complex defer patterns
fn test_order -> i32:
    var x = 0
    defer x = x + 100
    defer x = x * 10
    x = 5
    // Return value is 5 (captured before defers)
    x

fn main -> i32:
    // The return value is captured before defers execute
    let v1 = test_order()
    assert(v1 == 5)

    // Defers in nested scopes
    var acc = 0
    defer acc = acc + 10
    acc = 32
    // acc is 32 at end, defer runs but return value already captured
    if acc == 32 then 0 else 1
