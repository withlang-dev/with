//! expect-stdout: ok

// #622 regression guard: an array binding (no slice annotation) keeps its real
// length, and passing it to a slice parameter still works — only the unsafe
// slice-from-array-literal binding is rejected.
fn sumlen(arr: []i32) -> i32:
    arr.len() as i32

fn main:
    let xs: List[i32] = [10, 20, 30, 40]
    assert(xs.len() as i32 == 4)
    assert(sumlen(xs) == 4)
    print("ok")
