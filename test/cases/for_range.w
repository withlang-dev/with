// Test: For loop with range
fn main() -> i32 =
    var sum = 0
    for i in 1..11:
        sum = sum + i
    // 1+2+3+4+5+6+7+8+9+10 = 55
    if sum == 55 then 0 else 1
