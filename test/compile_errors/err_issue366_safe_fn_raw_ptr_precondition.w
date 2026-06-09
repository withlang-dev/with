//! expect-error: safe function relies on caller-guaranteed raw pointer validity

fn read_first(p: *const i32) -> i32:
    unsafe *p
