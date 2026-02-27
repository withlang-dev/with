// Test loop with break
fn main -> i32:
    let mut count = 0
    loop:
        count = count + 1
        if count == 5:
            break
    println(count)

    // Nested loops with break
    let mut total = 0
    let mut i = 0
    while i < 3:
        let mut j = 0
        while j < 3:
            if j == 2:
                break
            total = total + 1
            j = j + 1
        i = i + 1
    println(total)
