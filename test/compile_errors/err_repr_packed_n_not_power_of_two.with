//! expect-check-fail: @[repr(packed(N))] takes a power of two from 1 to 65536

// Spec §16.4 (#1421): "`@[repr(packed(N))]`, with `N` a power of two".

@[repr(packed(3))]
type Hdr { a: u16, b: u32 }

fn main:
    print("unreachable")
