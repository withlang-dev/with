//! expect-stdout: 3
//! expect-stdout: 3
//! expect-stdout: 2
//! expect-stdout: 4

// #1517 (§4.8a): a slice is `(ptr, len)`, and `s.len` reads its length; the
// field projection read 0.

fn count3(arr: []i32) -> i64:
    let n = arr.len
    n
fn count5(arr: []i32) -> i64: arr.len()
fn count_ref(arr: &[]i32) -> i64: arr.len

fn main:
    let a: [i32; 3] = [1, 2, 3]
    print(count3(a[..]))
    print(count5(a[..]))
    print(count_ref(a[1..]))
    let b: [i32; 4] = [1, 2, 3, 4]
    print(b.len)
