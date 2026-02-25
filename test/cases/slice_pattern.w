// Test: Slice patterns in match
fn main() -> i32 =
    let arr = [10, 20, 30]

    // Match on fixed array with exact length
    let result = match arr
        [a, b, c] -> a + b + c
        _ -> 0

    assert(result == 60)

    // Match with rest pattern
    let first_elem = match arr
        [x, ..rest] -> x
        _ -> 0

    assert(first_elem == 10)

    // Match empty vs non-empty
    let arr2 = [42]
    let val = match arr2
        [only] -> only
        _ -> 0

    assert(val == 42)

    println("all slice pattern tests passed")
    0
