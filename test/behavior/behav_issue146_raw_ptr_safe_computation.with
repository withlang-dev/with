//! expect-stdout: ok

fn raw_addr(p: *const i32) -> usize:
    p as usize

fn unrelated_pointer_difference_compiles:
    let a: i32 = 1
    let b: i32 = 2
    let p = &a as *const i32
    let q = &b as *const i32
    let _ = p - q

fn main:
    let arr: [4]i32 = [1, 2, 3, 4]
    let p: *const i32 = (&arr[0] as *const i32)
    let q = p + 2
    let r = q - 1
    let diff = q - p
    let addr = p as usize
    let p2 = addr as *const i32

    assert(diff == 8)
    assert(p == p2)
    assert(r == p + 1)
    assert(p < q)
    assert(raw_addr(p) == addr)
    unrelated_pointer_difference_compiles()
    print("ok")
