use std.encoding

fn expect(label: str, ok: bool):
    if ok:
        print(f"PASS: {label}\n")
    else:
        print(f"FAIL: {label}\n")

fn decode_must_fail_short() -> Result[str, DecodeError]:
    Err(DecodeError.InvalidLength(3))

fn main():
    // DecodeError variants constructible and matchable (T23: error surface)
    let e1 = DecodeError.InvalidLength(3)
    let e2 = DecodeError.InvalidByte(1, 255)
    let e3 = DecodeError.InvalidPadding(2)
    let e4 = DecodeError.NonCanonicalBits(0)
    match e1:
        DecodeError.InvalidLength(n) => expect("InvalidLength payload", n == 3)
        _ => expect("InvalidLength payload", false)
    match e2:
        DecodeError.InvalidByte(off, b) => expect("InvalidByte payload", off == 1 and b == 255)
        _ => expect("InvalidByte payload", false)
    match e3:
        DecodeError.InvalidPadding(off) => expect("InvalidPadding payload", off == 2)
        _ => expect("InvalidPadding payload", false)
    match e4:
        DecodeError.NonCanonicalBits(off) => expect("NonCanonical payload", off == 0)
        _ => expect("NonCanonical payload", false)
    // ? propagation through Result
    let r = decode_must_fail_short()
    match r:
        Ok(_) => expect("propagates Err", false)
        Err(err) => match err:
            DecodeError.InvalidLength(n) => expect("propagates Err", n == 3)
            _ => expect("propagates Err", false)
