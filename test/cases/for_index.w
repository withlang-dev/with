// Test for loop with index binding
fn main() -> i32 =
    let arr = [10, 20, 30, 40, 50]
    for val, i in arr:
        print(i)
        print(": ")
        println(val)
    0
