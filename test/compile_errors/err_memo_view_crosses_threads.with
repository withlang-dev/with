//! expect-check-fail: shares `cache`, whose contents change through a shared view

// D172 (§19.1): a `Memo` is not `Sync`; two scoped threads holding views
// of one would write its storage at once.
use std.memo

fn main:
    let cache: Memo[i32, i64] = Memo.new()
    scope s =>:
        let a = s.spawn(() => { cache.insert(1, 1); 0 })
        let b = s.spawn(() => { cache.insert(2, 2); 0 })
        let _ = a.join()
        let _ = b.join()
