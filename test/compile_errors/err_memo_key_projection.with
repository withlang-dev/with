//! expect-error: compares through the key projection of `Tag`

// D172 (§19.1): a `Memo` key hashes and compares as the compiler
// generates; a key projection would run user code inside the cache.
use std.memo
use std.traits

type Tag { id: i32, label: i32 }

impl Key for Tag:
    fn key(): self.id

fn main:
    let seen: Memo[Tag, i32] = Memo.new()
    seen.insert(Tag { id: 1, label: 2 }, 3)
