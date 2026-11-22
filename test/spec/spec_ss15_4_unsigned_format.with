//! expect-stdout: u8=200 u16=60000 u32=4000000000 u64=18000000000000000000 i32=-42
// §15.4: f-string interpolation of an unsigned integer prints its unsigned
// value, not the signed two's-complement reading of the bits (#639).
fn main:
    let a: u8 = 200
    let b: u16 = 60000
    let c: u32 = 4000000000
    let d: u64 = 18000000000000000000
    let e: i32 = -42
    print(f"u8={a} u16={b} u32={c} u64={d} i32={e}")
