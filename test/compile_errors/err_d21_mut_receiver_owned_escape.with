//! expect-check-fail: mut receiver is too weak; compiler effects require `move fn`

// D120: a struct of a List of values is a value, and `self` returned from a
// `mut fn` of one is a copy, not an escape; the D21 rule is pinned on an
// owner with identity.
resource type Owner { values: List[i32] }

impl Owner:
    mut fn return_receiver() -> Owner:
        self

fn main:
    var owner = Owner { values: List.new() }
    let escaped = owner.return_receiver()
    assert(escaped.values.len() == 0)
