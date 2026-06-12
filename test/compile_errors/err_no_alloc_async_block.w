//! expect-check-fail: async fiber/task creation allocates here

@[no_alloc]
fn main:
    let _task = async:
        1

