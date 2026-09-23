//! expect-stdout: 127 255 32767 65535
//! expect-stdout: 2147483647 4294967295 9223372036854775807
//! expect-stdout: 18446744073709551615
//! expect-stdout: a b false
//! expect-stdout: 9223372036854775807 9223372036854775808 18446744073709551614 18446744073709551615
//! expect-stdout: mid past top last
//! expect-stdout: 4611686018427387904 9223372036854775808 32 64 128
//! expect-stdout: 18446744073709551615

// #1452 (§4.4a): a variant at its repr's maximum and a u64 value above
// i64::MAX are values of the repr. The compiler panicked on both: the
// parser incremented after the last variant (i32 overflow at 2147483647)
// and parsed the literal into an i64 (u64 above i64::MAX). Matrix: every
// repr's maximum as the last variant; u64 at 2^64-1 with match and `==`;
// u64 auto-increment across i64::MAX and up to u64::MAX; @[flags] doubling
// to 2^63 in a u64 and to 128 in a u8.

enum A8: i8:
    Lo = 1
    Hi = 127

enum B8: u8:
    Lo = 1
    Hi = 255

enum A16: i16:
    Lo = 1
    Hi = 32767

enum B16: u16:
    Lo = 1
    Hi = 65535

enum A32: i32:
    A = 1
    B = 2147483647

enum B32: u32:
    Lo = 1
    Hi = 4294967295

enum A64: i64:
    Lo = 1
    Hi = 9223372036854775807

enum B64: u64:
    A = 1
    B = 18446744073709551615

enum C64: u64:
    Mid = 9223372036854775807
    Past
    Top = 18446744073709551614
    Last

@[flags]
enum F64: u64:
    A = 4611686018427387904
    B

@[flags]
enum F8: u8:
    A = 32
    B
    C

enum Mixed: u64:
    Small = 3
    Huge = 18446744073709551615

fn b64_name(k: &B64) -> str:
    match k:
        .A => "a".clone()
        .B => "b".clone()

fn c64_name(k: C64) -> str:
    match k:
        .Mid => "mid".clone()
        .Past => "past".clone()
        .Top => "top".clone()
        .Last => "last".clone()

fn main:
    print(f"{A8.Hi as i8} {B8.Hi as u8} {A16.Hi as i16} {B16.Hi as u16}")
    print(f"{A32.B as i32} {B32.Hi as u32} {A64.Hi as i64}")
    print(B64.B as u64)
    print(f"{b64_name(B64.A)} {b64_name(B64.B)} {B64.B == B64.A}")
    print(f"{C64.Mid as u64} {C64.Past as u64} {C64.Top as u64} {C64.Last as u64}")
    print(f"{c64_name(C64.Mid)} {c64_name(C64.Past)} {c64_name(C64.Top)} {c64_name(C64.Last)}")
    print(f"{F64.A as u64} {F64.B as u64} {F8.A as u8} {F8.B as u8} {F8.C as u8}")
    print(f"{Mixed.Huge as u64}")
