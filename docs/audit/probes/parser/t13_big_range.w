// T13: range pattern with bounds >= 2^31. Parser.w:6450-6458 uses
// `val64 as i32` (wraps) for start but parse_int (clamps) for end.
fn in_big(x: i64) -> i32:
    match x:
        0x80000000..0x80000001 => 1
        _ => 0

fn main:
    assert(in_big(2147483648i64) == 1)
    assert(in_big(5i64) == 0)
