//! expect-stdout: 200 200 200 200 200
//! expect-stdout: 40000 40000 40000
//! expect-stdout: 3000000000 3000000000 3000000000
//! expect-stdout: -3 -3 100 -7
//! expect-stdout: 200 200 40000
//! expect-stdout: 201
//! expect-stdout: 64 129

// #1454 (§4.4a): `value as T` extracts the underlying integer; an unsigned
// repr's value is unsigned. `Kind.Hi as i32` (u8 200) was -56: codegen
// asked whether an enum operand is unsigned and answered no for every enum,
// so the widening was a sext. Matrix: u8 / u16 / u32 values past the sign
// bit into i16 / i32 / i64 / u32 / u64 and the same width; signed reprs
// keep sign extension; a by-value param, a `&Kind` param, a loop over
// an array; `as i32` then `/`.

@[flags]
enum P: u8:
    Low = 1
    Top = 128

enum Kind: u8:
    Red = 1
    Hi = 200

enum W: u16:
    A = 1
    B = 40000

enum K: u32:
    A = 1
    C = 3000000000

enum S: i8:
    Neg = -3
    Pos = 100

enum S32: i32:
    Neg = -7
    Pos = 7

impl Copy for Kind
impl Copy for W

fn via_param(k: Kind) -> i32: k as i32
fn via_ref(k: &Kind) -> i64: k as i64
fn wide_of(w: W) -> i64: w as i64

fn main:
    print(f"{Kind.Hi as i32} {Kind.Hi as i64} {Kind.Hi as u32} {Kind.Hi as i16} {Kind.Hi as u8}")
    print(f"{W.B as i32} {W.B as i64} {W.B as u64}")
    print(f"{K.C as i64} {K.C as u64} {K.C as u32}")
    print(f"{S.Neg as i32} {S.Neg as i64} {S.Pos as i32} {S32.Neg as i64}")
    let k = Kind.Hi
    print(f"{via_param(k)} {via_ref(k)} {wide_of(W.B)}")
    var total: i64 = 0
    for kk in [Kind.Red, Kind.Hi]:
        total = total + (kk as i64)
    print(total)
    print(f"{(P.Top as i32) / 2} {(P.Top | P.Low) as u8}")
