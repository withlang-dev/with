//! expect-stdout: ok

// Test: Vec with for loop and pipeline

fn double(x: i32) -> i32:
    x * 2

fn add_ten(x: i32) -> i32:
    x + 10

fn main:
    // Pipeline with simple functions
    let result = 5 |> double |> add_ten
    assert(result == 20)

    // For loop accumulation
    var total = 0
    for i in 0..4:
        total += i
    assert(total == 6)

    print("ok")
