// Test for-in iteration with accumulation
fn sum_array(arr: [5]i32) -> i32:
    var total = 0
    for x in arr
        total = total + x
    total

fn main -> i32:
    let a = [1, 2, 3, 4, 5]
    println(sum_array(a))
    let b = [10, 20, 30, 40, 50]
    println(sum_array(b))
