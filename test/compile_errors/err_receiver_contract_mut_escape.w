//! expect-error: mut receiver is too weak; compiler effects require `move fn`

// D120: a struct of values is a value; this one is declared a resource
// so it still moves and still takes no copy.
resource type Invalid { values: List[i32] }

impl Invalid:
    mut fn take() -> Invalid: self

fn main:
    var value = Invalid { values: List.new() }
    let _ = value.take()
