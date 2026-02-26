fn sum_arr(arr: [5]i32) -> i32 =
    let mut total = 0
    let mut i = 0
    while i < 5:
        total = total + arr[i]
        i = i + 1
    total

fn main() -> i32 =
    let a = [1, 2, 3, 4, 5]
    println(sum_arr(a))
    let b = [10, 20, 30, 40, 50]
    println(sum_arr(b))
    0
