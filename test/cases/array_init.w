// Test array initialization and operations
fn main() -> i32 =
    let a = [1, 2, 3, 4, 5]
    println(a[0])
    println(a[4])
    println(a.len)

    // Sum via for loop
    let mut sum = 0
    for x in a:
        sum = sum + x
    println(sum)
    0
