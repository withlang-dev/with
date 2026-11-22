//! expect-error: `store` expects at least 1 argument(s), found 0

// #2358 with §14.17.1 (#1861): an Atomic method's trailing Ordering may be
// omitted, but its value argument may not — MirLower materializes only the
// omitted Ordering, so `store()` silently stored the SeqCst constant before.

use std.collections.Atomic

fn main:
    var a = Atomic[i32].new(0)
    a.store()
    print(a.load())
