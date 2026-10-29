//! expect-error: comparison operands must have compatible types: `*const u8` and `u8`; `*const u8` is a pointer or reference, and its pointee is one dereference further (`*p`)

// #893: `*(ptrs[1])` dereferences the element's exact `&*const u8` (D22
// §6.6: resolution keeps the exact reference type), so it is the pointer the
// element holds; the pointee is `**ptrs[1]`. The error said only "compatible
// types", which read as a value that matched no type at all.
fn main:
    let a: [3]u8 = [7, 8, 9]
    let ptrs: [2]*const u8 = [&raw const a[0], &raw const a[1]]
    let v = *(ptrs[1])
    let b: u8 = 8
    print(f"{v == b}")
