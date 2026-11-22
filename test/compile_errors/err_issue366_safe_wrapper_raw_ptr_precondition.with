//! expect-error: safe function relies on caller-guaranteed raw pointer validity

unsafe fn read_first(p: *const i32) -> i32:
    *p

fn wrapper(p: *const i32) -> i32:
    unsafe { read_first(p) }
