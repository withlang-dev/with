//! expect-stdout: ok

fn main:
    var arr: [4]i32 = [1, 2, 3, 4]
    let p: *mut i32 = &raw mut arr[0] as *mut i32
    let cp: *const i32 = &arr[0] as *const i32

    assert(unsafe *cp == 1)
    assert(unsafe p[1] == 2)

    var p_copy = p
    let pp: *mut *mut i32 = &raw mut p_copy
    assert(unsafe **pp == 1)
    assert(unsafe *(p + 2) == 3)

    unsafe *p = 10
    unsafe p[1] = 20
    assert(arr[0] == 10)
    assert(arr[1] == 20)

    let sum = unsafe { *p + *(p + 1) }
    assert(sum == 30)

    let block_value = unsafe:
        *(p + 2)
    assert(block_value == 3)

    print("ok")
