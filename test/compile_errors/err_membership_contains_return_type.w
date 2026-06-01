//! expect-error: Contains.contains used by `in` must return bool

type Weird { value: i32 }

fn Weird.contains(self: &Self, value: &i32) -> i32:
    1

fn main:
    let w = Weird { value: 0 }
    let _ = 1 in w
