//! expect-error: comprehension filter must be bool

fn main:
    let xs = [x for x in 0..3 if 1]
