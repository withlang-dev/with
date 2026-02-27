// Test while loop with mutable counter
fn main -> i32:
    let mut sum = 0
    let mut i = 1
    while i <= 10:
        sum = sum + i
        i = i + 1
    println(sum)
