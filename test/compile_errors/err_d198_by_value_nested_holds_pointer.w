//! expect-check-fail: takes `Outer` by value, and field 'inner.items'
// D198 (§16.2b.5): a type holds a pointer when a record inside it does.
use c_import("typedef struct { const int *items; int n; } Span; typedef struct { int tag; Span inner; } Outer; static inline int outer_first(Outer o) { return o.inner.items[0]; }")

fn main:
    let o = Outer { tag: 1, inner: Span { items: 4096 as *const i32, n: 1 } }
    print(f"{outer_first(o)}")
