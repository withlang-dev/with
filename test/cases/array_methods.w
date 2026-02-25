// Test: Array methods
fn main() -> i32 =
    let arr = [10, 20, 30, 40, 50]

    // .len
    assert(arr.len == 5)

    // Indexing
    assert(arr[0] == 10)
    assert(arr[4] == 50)

    // .first() / .last()
    assert(arr.first() == 10)
    assert(arr.last() == 50)

    // .is_empty()
    assert(not arr.is_empty())

    // .contains()
    assert(arr.contains(30))
    assert(not arr.contains(99))

    // .sum()
    assert(arr.sum() == 150)

    println("all array method tests passed")
    0
