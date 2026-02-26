// Test break with value from loop
fn find_first_gt(threshold: i32) -> i32 =
    var i = 0
    loop
        i = i + 1
        if i * i > threshold:
            break i
    
fn main() -> i32 =
    let v = find_first_gt(50)
    println(v)
    let v2 = find_first_gt(100)
    println(v2)
    0
