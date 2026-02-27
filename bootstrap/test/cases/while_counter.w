// Test while loop with counter
fn count_digits(n: i32) -> i32:
    var count = 0
    var val = n
    if val == 0: return 1
    while val > 0
        val = val / 10
        count = count + 1
    count

fn main -> i32:
    println(count_digits(0))
    println(count_digits(5))
    println(count_digits(42))
    println(count_digits(12345))
