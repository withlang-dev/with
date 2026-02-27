// FLAGS: --no-std
// POSITIVE: core types available in no_std mode (Section 18.7)
fn main -> i32:
    let x: i32 = 42
    let y: bool = true
    let z: f64 = 3.14
    let arr = [1, 2, 3]
    assert(x == 42)
    assert(y == true)
    assert(arr[0] == 1)
    0
