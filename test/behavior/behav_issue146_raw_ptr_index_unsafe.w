//! expect-stdout: ok

fn read_first(p: *const i32) -> i32:
    unsafe: p[0]

unsafe fn read_second(p: *const i32) -> i32:
    p[1]

fn main:
    var arr: [4]i32 = [1, 2, 3, 4]
    let p: *mut i32 = (&raw mut arr[0] as *mut i32)

    unsafe:
        assert(p[1] == 2)
        p[1] = 9
        assert(p[1] == 9)

    assert(read_first(p as *const i32) == 1)
    let second = unsafe: read_second(p as *const i32)
    assert(second == 9)
    print("ok")
