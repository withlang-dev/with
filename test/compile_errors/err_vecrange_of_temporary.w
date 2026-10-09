//! expect-check-fail: ephemeral value borrows a temporary that dies at the end of this statement

// A VecRange views its Vec; a temporary Vec dies when the statement ends,
// so its halves cannot be bound (§21.1). Before, `split_at` on a temporary
// bound two dangling views with no diagnostic.
fn main:
    let _parts = [1, 2, 3].split_at_mut(1)
