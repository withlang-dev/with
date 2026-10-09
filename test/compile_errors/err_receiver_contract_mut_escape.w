//! expect-error: mut receiver is too weak; compiler effects require `move fn`

type Invalid { values: List[i32] }

impl Invalid:
    mut fn take() -> Invalid: self

fn main:
    var value = Invalid { values: List.new() }
    let _ = value.take()
