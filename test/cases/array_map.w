// Test array functional operations
fn main() -> i32 =
    let arr = [1, 2, 3, 4, 5]
    var sum = 0
    for x in arr
        sum = sum + x
    println(sum)
    println(arr.len)
    println(arr[0])
    println(arr[4])
    0
