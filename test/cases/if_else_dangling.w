//! expect-stdout: ok
extern fn print(s: str) -> void
extern fn int_to_string(n: i32) -> str

// Test: else belongs to the outer if, not the inner if (dangling-else).
fn main:
    // For loop inside if, else belongs to outer if
    var x = 0
    let condition = true
    if condition:
        for i in 0..3:
            if i == 1:
                x = x + 1
    else:
        x = 100
    assert(x == 1)

    // Nested if-inside-if, else belongs to outer
    var y = 0
    if false:
        if true:
            y = 50
    else:
        y = 100
    assert(y == 100)

    // else-if chains still work
    var z = 0
    if false:
        z = 1
    else if false:
        z = 2
    else:
        z = 3
    assert(z == 3)

    // Inline if-else expressions unaffected
    let v = if true: 42 else: 99
    assert(v == 42)

    print("ok")
