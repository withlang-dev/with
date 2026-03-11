//! expect-stdout: ok

// Integration test: standalone program
// Exercises: function definition, if expression, comparison

fn helper(x: i32) -> i32:
    x + 1

fn main:
    let result = helper(41)
    if result == 42:
        println("ok")
