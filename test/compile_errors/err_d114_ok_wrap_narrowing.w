//! expect-check-fail: implicit integer narrowing or sign change from `isize` to `i32`

// D114 (§4.2.6, §4.9): an implicit `Ok` wrap demands the payload type, so an
// `isize` tail does not narrow into `Result[i32, E]`; it was accepted and
// MIR then refused the payload (an internal compiler error).
fn count() -> Result[i32, str]:
    var n = 0
    n = n + 1
    n

fn main:
    print(count() ?? -1)
