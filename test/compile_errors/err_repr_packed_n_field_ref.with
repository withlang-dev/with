//! expect-check-fail: cannot create a reference to field 'b' of a repr(packed(2)) type: its natural alignment 4 exceeds 2

// Spec §16.4 (#1421): "A reference to a field whose natural alignment
// exceeds N is a compile error, as for `repr(packed)`." `b` sits at offset
// 2; a `&u32` to it would be unaligned.

@[repr(packed(2))]
type Hdr { a: u16, b: u32 }

fn main:
    let h = Hdr { a: 1, b: 2 }
    let r = &h.b
    print(f"{r}")
