// Test: built-in array methods
fn main() -> i32 =
    let arr = [10, 20, 30, 40, 50]

    // len
    assert(arr.len() == 5)

    // is_empty
    assert(not arr.is_empty())

    // first / last
    assert(arr.first() == 10)
    assert(arr.last() == 50)

    // contains
    assert(arr.contains(30))
    assert(not arr.contains(99))

    // reverse
    let rev = arr.reverse()
    assert(rev.first() == 50)
    assert(rev.last() == 10)

    0
