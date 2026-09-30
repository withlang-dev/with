//! expect-stdout: 1267650600228229401496703205376
//! expect-stdout: -170141183460469231731687303715884105728
//! expect-stdout: 340282366920938463463374607431768211455
//! expect-stdout: 10000000000000000000000000
//! expect-stdout: ffffffffffffffffffffffffffffffff 0x10000000000000000
//! expect-stdout: [ -18446744073709551616]
//! expect-stdout: ffffffff 4294967295 11001000
//! expect-stdout: [  4294967295] [00000200]
//! expect-stdout: -9223372036854775808
//! expect-stdout: at 4294967295: ffffffff

// #1922 (§4.1, §15.4.3): an integer prints its whole value at its own
// width and signedness. A 128-bit value went through the 64-bit formatter
// and lost its high half (`1 << 100` printed 0); under a format spec an
// unsigned or narrow value was sign-extended to 64 bits (`u32` 0xffffffff
// printed `ffffffffffffffff` under `:x` and `-1` under `:>12`), and
// `i64::MIN` under a decimal spec overflowed negating itself.

fn main:
    let one: i128 = 1
    let big = one << 100
    print(f"{big}")
    let min = one << 127
    print(f"{min}")
    let umax: u128 = 0xffffffffffffffffffffffffffffffff
    print(f"{umax}")
    let dec: u128 = 10000000000000000000000000
    print(f"{dec}")
    let two64: u128 = 18446744073709551616
    print(f"{umax:x} {two64:#x}")
    let neg: i128 = 0 - 18446744073709551616
    print(f"[{neg:>22}]")
    let a: u32 = 0xffffffff
    let c: u8 = 200
    print(f"{a:x} {a} {c:b}")
    let w: u16 = 200
    print(f"[{a:>12}] [{w:08}]")
    let lo: i64 = 0 - 9223372036854775807 - 1
    print(f"{lo:d}")
    print(f"at {a}: {a:x}")
