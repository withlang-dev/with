//! expect-error: `Memo`'s value `str` holds a `str`

// D172 (§19.1): a `Memo` value is copied out, so it shares no
// representation with what the cache holds.
use std.memo

fn main:
    let names: Memo[i32, str] = Memo.new()
    names.insert(1, "one")
