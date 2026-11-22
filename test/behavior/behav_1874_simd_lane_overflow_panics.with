//! expect-exit: 134
//! expect-stderr: integer overflow

// §4.3d (D78, #1874): integer lanes follow §4.2 per lane — a lane that
// overflows panics under the default overflow mode.
fn bump(v: i8x16) -> i8x16: v + 1

fn main:
    let v = i8x16(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 127)
    let r = bump(v)
    print(f"{r[15]}")
