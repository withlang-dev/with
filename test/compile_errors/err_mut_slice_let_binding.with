//! expect-check-fail: can only be a function parameter type

// #604 stage 1: []mut T exists only in parameter position; a local binding
// would let the mutable view outlive its call-local exclusivity window.

fn main:
    let s: []mut i32 = []
    print("no")
