// Test for loop with range
fn main -> i32:
    var sum = 0
    for i in 0..5
        sum = sum + i
    println(sum)

    var prod = 1
    for i in 1..=5
        prod = prod * i
    println(prod)
