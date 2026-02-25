// Test: slice type and array slicing
fn main() -> i32 =
    let arr = [10, 20, 30, 40, 50]
    let s: []i32 = arr[1..4]
    assert(s.len == 3)
    assert(s[0] == 20)
    assert(s[1] == 30)
    assert(s[2] == 40)

    // Slice the whole array
    let all: []i32 = arr[0..5]
    assert(all.len == 5)
    assert(all[0] == 10)
    assert(all[4] == 50)

    // Sum via for-in over slice
    var sum: i32 = 0
    for v in s:
        sum += v
    assert(sum == 90)

    0
