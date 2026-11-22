//! expect-check-fail: wrong argument type

// #604: an immutable []T cannot be passed where []mut T is expected (the d1
// gate in types_compatible; writes through the view would break the reader's
// immutability assumption).

fn fill(buf: []mut i32): ()

fn use_view(xs: []i32):
    fill(xs)

fn main:
    print("no")
