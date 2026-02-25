// Test: nested arrays / 2D array access
fn main() -> i32 =
    let row1: [3]i32 = [1, 2, 3]
    let row2: [3]i32 = [4, 5, 6]
    let row3: [3]i32 = [7, 8, 9]

    // Sum specific elements
    let sum = row1[0] + row2[1] + row3[2]
    // 1 + 5 + 9 = 15
    assert(sum == 15)

    // Sum all elements via loops
    var total: i32 = 0
    for x in row1:
        total += x
    for x in row2:
        total += x
    for x in row3:
        total += x
    // 1+2+3+4+5+6+7+8+9 = 45
    assert(total == 45)

    // Verify lengths
    assert(row1.len == 3)
    assert(row2.len == 3)

    0
