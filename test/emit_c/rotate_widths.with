//! expect-stdout: u8 75 150 150 45 75
//! expect-stdout: i8 75 -106 -106 45 75
//! expect-stdout: u16 49152 32769 32769 3 49152
//! expect-stdout: u32 3221225472 2147483649 2147483649 3 3221225472
//! expect-stdout: i32 -1073741824 -2147483647 -2147483647 3 -1073741824
//! expect-stdout: u64 13835058055282163712 9223372036854775809 9223372036854775809 3 13835058055282163712
//! expect-stdout: i64 -4611686018427387904 -9223372036854775807 -9223372036854775807 3 -4611686018427387904

// #1006: rotate_left/rotate_right at every integer width, the count taken
// modulo the width. The C backend emitted the 32-bit form for every type
// and shifted by 32 when the count was 0 (undefined behavior in C, as it
// was poison in the LLVM backend before 9475185a). Each row rotates the
// bit pattern 1000...0001 (0x96 for the 8-bit rows): rotate_right(1),
// rotate_left(0), rotate_left(width), rotate_left(width + 1) and
// rotate_left(-1), which is rotate_right(1).

fn main:
    let a: u8 = 150
    print(f"u8 {a.rotate_right(1)} {a.rotate_left(0)} {a.rotate_left(8)} {a.rotate_left(9)} {a.rotate_left(-1)}")
    let b: i8 = -106
    print(f"i8 {b.rotate_right(1)} {b.rotate_left(0)} {b.rotate_left(8)} {b.rotate_left(9)} {b.rotate_left(-1)}")
    let c: u16 = 32769
    print(f"u16 {c.rotate_right(1)} {c.rotate_left(0)} {c.rotate_left(16)} {c.rotate_left(17)} {c.rotate_left(-1)}")
    let d: u32 = 2147483649
    print(f"u32 {d.rotate_right(1)} {d.rotate_left(0)} {d.rotate_left(32)} {d.rotate_left(33)} {d.rotate_left(-1)}")
    let e: i32 = -2147483647
    print(f"i32 {e.rotate_right(1)} {e.rotate_left(0)} {e.rotate_left(32)} {e.rotate_left(33)} {e.rotate_left(-1)}")
    let f: u64 = 9223372036854775809
    print(f"u64 {f.rotate_right(1)} {f.rotate_left(0)} {f.rotate_left(64)} {f.rotate_left(65)} {f.rotate_left(-1)}")
    let g: i64 = -9223372036854775807
    print(f"i64 {g.rotate_right(1)} {g.rotate_left(0)} {g.rotate_left(64)} {g.rotate_left(65)} {g.rotate_left(-1)}")
