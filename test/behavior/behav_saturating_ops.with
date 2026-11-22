//! expect-stdout: ok
// §4: saturating arithmetic +| -| *| clamps at the type's bounds.
fn main:
    assert((250u8 +| 20u8) == 255)
    assert((3u8 -| 9u8) == 0)
    assert((20u8 *| 20u8) == 255)
    assert((120i8 +| 20i8) == 127)
    let nlo: i8 = -120
    assert((nlo -| 20i8) == -128)
    assert((100i8 *| 2i8) == 127)
    let nc: i8 = -100
    assert((nc *| 2i8) == -128)
    let big: u32 = 4294967290
    assert((big +| 10u32) == 4294967295)
    print("ok")
