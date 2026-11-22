//! expect-stdout: ok
// §16.4: an @[repr(packed)] struct has no padding (sizeof == sum of fields) and
// its fields round-trip through unaligned reads/writes.
@[repr(packed)]
type Packed { a: u8, b: i32, c: u16 }
fn main:
    var p = Packed { a: 1, b: 2, c: 3 }
    p.b = 0x11223344
    p.c = 0xABCD
    if sizeof[Packed]() == 7 and p.a == 1 and p.b == 0x11223344 and p.c == 0xABCD: print("ok")
    else: print("bad")
