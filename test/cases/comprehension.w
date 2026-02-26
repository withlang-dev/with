// Test: array comprehensions
fn main -> i32:
    // Basic comprehension: [x * x for x in 0..5]
    let squares = [x * x for x in 0..5]
    assert(squares[0] == 0)
    assert(squares[1] == 1)
    assert(squares[2] == 4)
    assert(squares[3] == 9)
    assert(squares[4] == 16)

    // Comprehension with expression
    let doubled = [x * 2 for x in 1..4]
    assert(doubled[0] == 2)
    assert(doubled[1] == 4)
    assert(doubled[2] == 6)

    // Sum of comprehension elements
    var sum: i32 = 0
    let vals = [x + 1 for x in 0..5]
    var i: i32 = 0
    while i < 5:
        sum += vals[i]
        i += 1
    assert(sum == 15)

