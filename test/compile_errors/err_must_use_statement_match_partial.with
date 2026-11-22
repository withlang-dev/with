//! expect-check-fail: non-exhaustive match: missing variant 'Err'

@[must_use]
enum Status { Ok | Err }

fn main:
    let status: Status = .Ok
    match status:
        .Ok => print("ok")
