// Test: for loop with break and continue
fn main() -> i32 =
    // Sum numbers 1..20, skip multiples of 3, break at 15
    var sum: i32 = 0
    for i in 1..20:
        if i == 15 then break
        if i % 3 == 0 then continue
        sum += i

    // 1+2+4+5+7+8+10+11+13+14 = 75
    assert(sum == 75)

    // Accumulate until we exceed a threshold
    var total: i32 = 0
    for j in 0..100:
        total += j
        if total >= 42 then break

    // 0+1+2+3+4+5+6+7+8+9 = 45 >= 42
    assert(total >= 42)

    0
