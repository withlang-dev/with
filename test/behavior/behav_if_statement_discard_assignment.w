//! expect-stdout: ok

type Handle {
    ptr: *mut i32,
}

impl Copy for Handle

fn keep(handle: Handle) -> Handle:
    handle

fn choose(flag: i32, handle: Handle) -> i32:
    var next = handle
    var seen = 0
    if flag == 1:
        seen = 10
    else if flag == 2:
        next = keep(next)
    else if flag == 3:
        next = keep(next)
    else:
        seen = 40

    unsafe:
        *next.ptr = *next.ptr + seen + 1
    seen

fn main:
    var value = 0
    let handle = Handle { ptr: &raw mut value as *mut i32 }

    assert(choose(1, handle) == 10)
    assert(value == 11)
    assert(choose(2, handle) == 0)
    assert(value == 12)
    assert(choose(3, handle) == 0)
    assert(value == 13)
    assert(choose(4, handle) == 40)
    assert(value == 54)

    print("ok")
