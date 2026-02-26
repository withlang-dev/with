fn main() -> i32 =
    // Nested loops with break
    let mut result = 0
    let mut i = 0
    while i < 5:
        let mut j = 0
        while j < 5:
            if i * j > 6: break
            result = result + 1
            j = j + 1
        i = i + 1
    println(result)

    // Count down
    let mut n = 10
    while n > 0:
        n = n - 1
    println(n)
    0
