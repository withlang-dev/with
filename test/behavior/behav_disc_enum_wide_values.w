//! expect-stdout: -128 -3 127
//! expect-stdout: -32768 -300 32767
//! expect-stdout: -2147483648 -5 2147483647
//! expect-stdout: -9223372036854775808 -5000000000 5000000000 9223372036854775807
//! expect-stdout: 255 65535 3000000000 4294967295
//! expect-stdout: 5000000000 9223372036854775807
//! expect-stdout: -2 -1 0 2147483647 2147483648
//! expect-stdout: -1 0 1
//! expect-stdout: lo neg big hi
//! expect-stdout: a b big hi
//! expect-stdout: a big top
//! expect-stdout: lo neg hi
//! expect-stdout: true false false
//! expect-stdout: px py qy qx -10 4000000000
//! expect-stdout: quit
//! expect-stdout: move 5
//! expect-stdout: stop
//! expect-stdout: 3000000000
//! expect-stdout: 1 2 4 4294967296 8589934592
//! expect-stdout: 250 251 252

// #1451 (§4.4a): a discriminant is any value of the repr — below 0 and
// above i32::MAX included. The parser counted discriminants in an i32
// (`5000000000` truncated to 705032704) and a negative one read as "no
// discriminant" and lowered as its variant index (`B = -3` printed 1); MIR
// switch tables were i32. Matrix: every repr at its extremes, auto-increment
// across 0 and past i32::MAX, an inferred-i32 enum, two enums sharing
// variant names with different values, a payload enum with a wide and a
// negative tag, match / `==` / `as`, and @[flags] doubling past 2^32.

@[flags]
enum F: i64:
    A
    B
    C
    Big = 4294967296
    Next

enum H: u8 { P = 250 | Q | R }

enum S8: i8:
    Lo = -128
    Neg = -3
    Hi = 127

enum S16: i16:
    Lo = -32768
    Neg = -300
    Hi = 32767

enum S32: i32:
    Lo = -2147483648
    Neg = -5
    Hi = 2147483647

enum S64: i64:
    Lo = -9223372036854775808
    Neg = -5000000000
    Big = 5000000000
    Hi = 9223372036854775807

enum U8: u8:
    A = 1
    Hi = 255

enum U16: u16:
    A = 1
    Hi = 65535

enum U32: u32:
    A = 1
    B = 2
    Big = 3000000000
    Hi = 4294967295

enum U64: u64:
    A = 1
    Big = 5000000000
    Top = 9223372036854775807

// auto-increment across zero and past i32::MAX
enum Run: i64:
    M2 = -2
    M1
    Z
    Wide = 2147483647
    Wider

// no repr: the inferred i32 backing takes a negative value
enum Inferred:
    Neg = -1
    Zero
    One

// two enums sharing variant names with different values
enum P: i32:
    X = -10
    Y = 3000000

enum Q: i64:
    Y = -4000000000
    X = 4000000000

// a payload discriminant enum with wide and negative tags
enum Msg: i64:
    Quit = -7
    Move(i32, i32) = 6000000000
    Stop = 1

impl Copy for S64
impl Copy for U32

fn s64_name(v: S64) -> str:
    match v:
        .Lo => "lo".clone()
        .Neg => "neg".clone()
        .Big => "big".clone()
        .Hi => "hi".clone()

fn u32_name(v: U32) -> str:
    match v:
        U32.A => "a".clone()
        U32.B => "b".clone()
        U32.Big => "big".clone()
        U32.Hi => "hi".clone()

fn u64_name(v: &U64) -> str:
    match v:
        .A => "a".clone()
        .Big => "big".clone()
        .Top => "top".clone()

fn s8_name(v: S8) -> str:
    match v:
        .Lo => "lo".clone()
        .Neg => "neg".clone()
        .Hi => "hi".clone()

fn p_name(v: P) -> str:
    match v:
        .X => "px".clone()
        .Y => "py".clone()

fn q_name(v: Q) -> str:
    match v:
        .Y => "qy".clone()
        .X => "qx".clone()

fn msg_text(m: &Msg) -> str:
    match m:
        .Quit => "quit".clone()
        .Move(a, b) => f"move {a + b}"
        .Stop => "stop".clone()

fn main:
    print(f"{S8.Lo as i8} {S8.Neg as i8} {S8.Hi as i8}")
    print(f"{S16.Lo as i16} {S16.Neg as i16} {S16.Hi as i16}")
    print(f"{S32.Lo as i32} {S32.Neg as i32} {S32.Hi as i32}")
    print(f"{S64.Lo as i64} {S64.Neg as i64} {S64.Big as i64} {S64.Hi as i64}")
    print(f"{U8.Hi as u8} {U16.Hi as u16} {U32.Big as u32} {U32.Hi as u32}")
    print(f"{U64.Big as u64} {U64.Top as u64}")
    print(f"{Run.M2 as i64} {Run.M1 as i64} {Run.Z as i64} {Run.Wide as i64} {Run.Wider as i64}")
    print(f"{Inferred.Neg as i32} {Inferred.Zero as i32} {Inferred.One as i32}")
    print(f"{s64_name(S64.Lo)} {s64_name(S64.Neg)} {s64_name(S64.Big)} {s64_name(S64.Hi)}")
    print(f"{u32_name(U32.A)} {u32_name(U32.B)} {u32_name(U32.Big)} {u32_name(U32.Hi)}")
    print(f"{u64_name(U64.A)} {u64_name(U64.Big)} {u64_name(U64.Top)}")
    print(f"{s8_name(S8.Lo)} {s8_name(S8.Neg)} {s8_name(S8.Hi)}")
    print(f"{U32.Big == U32.Big} {U32.Big == U32.B} {S64.Neg == S64.Big}")
    print(f"{p_name(P.X)} {p_name(P.Y)} {q_name(Q.Y)} {q_name(Q.X)} {P.X as i32} {Q.X as i64}")
    let ms = [Msg.Quit, Msg.Move(2, 3), Msg.Stop]
    for m in ms:
        print(msg_text(m))
    let k = U32.Big
    let code: u32 = k as u32
    print(code)
    print(f"{F.A as i64} {F.B as i64} {F.C as i64} {F.Big as i64} {F.Next as i64}")
    print(f"{H.P as u8} {H.Q as u8} {H.R as u8}")
