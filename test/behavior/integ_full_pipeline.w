//! expect-stdout: 42

// Integration test: full compiler pipeline
// Exercises: function definition, arithmetic, function call, print

fn double(x: i32) -> i32:
    x * 2

fn main:
    let n = 21
    let result = double(n)
    print(int_to_string(result))
