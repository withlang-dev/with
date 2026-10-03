//! expect-stdout: ba ba 186
//! expect-stdout: ba 10
//! expect-stdout: beef deadbeef ffffffff
//! expect-stdout: fe fe -2 fe
//! expect-stdout: fffe fffffffe fffffffffffffffe
//! expect-stdout: 0xfe 11111110 376 FE

// #1907 (§15.4.3): a value under a hex, binary or octal spec prints its own
// bits at its own width. An unsigned byte was sign-extended to 64 bits
// before formatting (`u8` 0xba printed `ffffffffffffffba`); after #1922 a
// signed narrow value still was (`i8` -2 printed `fffffffffffffffe`): the
// bit pattern of an i8 is two hex digits.

fn main:
    let b: u8 = 0xba
    print(f"{b:02x} {b:x} {b}")
    var a: [u8; 2] = [0xba as u8, 0x10 as u8]
    print(f"{a[0]:02x} {a[1]:02x}")
    let s: u16 = 0xbeef
    let w: u32 = 0xdeadbeef
    let m: u32 = 0xffffffff
    print(f"{s:x} {w:x} {m:x}")
    let n: i8 = -2
    let n_copy = n
    print(f"{n:x} {n:02x} {n} {n_copy:x}")
    let n16: i16 = -2
    let n32: i32 = -2
    let n64: i64 = -2
    print(f"{n16:x} {n32:x} {n64:x}")
    print(f"{n:#x} {n:b} {n:o} {n:X}")
