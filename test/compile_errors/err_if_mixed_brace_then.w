//! expect-check-fail: cannot mix

fn main:
    let x = 5
    if x > 0 {
        print("positive")
    } else if x < 0 then print("negative")
    else print("zero")
