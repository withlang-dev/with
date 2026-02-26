// Test nested array operations
fn sum_array(arr: [5]i32) -> i32 =
    let mut total = 0
    for i in 0..5:
        total = total + arr[i]
    total

fn main() -> i32 =
    let a = [10, 20, 30, 40, 50]
    println(sum_array(a))
    println(a[0] + a[4])
    println(a.len)
    0
