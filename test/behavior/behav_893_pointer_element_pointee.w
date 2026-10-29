//! expect-stdout: true true

// #893: an element that holds a pointer is reached in two dereferences: the
// first reads the element through its exact `&*const u8` (D22 §6.6), the
// second the pointer. No cast is needed for either.
fn main:
    let a: [3]u8 = [7, 8, 9]
    let ptrs: [2]*const u8 = [&raw const a[0], &raw const a[1]]
    let v = unsafe **ptrs[1]
    let p = *ptrs[0]
    print(f"{v == 8} {unsafe *p == 7}")
