//! expect-stdout: 8 3 15 256 1099511627776 9 255 7

// §4.2.1 (#1820): the context type reaches the left operand of a shift and
// both operands of `& | ^` when they are untyped literals, as Rust and Swift
// type them; a shift amount types on its own. Each was an i32 computation
// narrowed at the demand ("implicit integer narrowing"), and `1 << 40`
// shifted an i32.
fn shl() -> u32: 1 << 8

fn main:
    let a: u8 = 1 << 3
    let b: u8 = 1 | 2
    let c: u32 = 0xFF & 0x0F
    let d: u64 = 1 << 40
    let e: u8 = (1 << 3) + 1
    let f: u8 = ~0
    let g: u16 = 5 ^ 2
    print(f"{a} {b} {c} {shl()} {d} {e} {f} {g}")
