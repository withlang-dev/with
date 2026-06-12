//! expect-check-fail: comprehension allocates here

@[no_alloc]
fn main:
    let _xs = [x for x in 0..3]

