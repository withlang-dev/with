//! expect-stdout: ok

fn main:
    let arr: [4]i32 = [1, 2, 3, 4]
    let p: *const i32 = (&arr[0] as *const i32)
    let q = p + 2
    let r = q - 1
    let diff = q - p
    let addr = p as usize
    let p2 = addr as *const i32

    assert(diff == 2)
    assert(p == p2)
    assert(r == p + 1)
    print("ok")
