fn main -> i32:
    let arr = [10, 20, 30, 40, 50]
    println(arr[0])
    println(arr[4])
    let mut sum = 0
    for i in 0..5:
        sum = sum + arr[i]
    println(sum)
