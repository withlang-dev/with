//! expect-stdout: 42

// Integration test: full compiler pipeline
// Exercises: function definition, arithmetic, function call, println

fn double(x: i32) -> i32:
    x * 2

fn main:
    let n = 21
    let result = double(n)
    println(int_to_string(result))
