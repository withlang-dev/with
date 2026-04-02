//! expect-check-fail: format mode requires integer type
error LocalErr =
    Bad(msg: str)
    Empty

fn main:
    let err = LocalErr.Bad("boom")
    print(f"{err:x}")
