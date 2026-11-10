//! expect-check-fail: takes `Span` by value, and field 'items'
// D198 (§16.2b.5): a parameter passed by value whose type holds a pointer is a pointer parameter; safe code set the field to an address of its choosing.
use c_import("typedef struct { const int *items; int n; } Span; static inline int span_first_v(Span s) { return s.n > 0 ? s.items[0] : 0; }")

fn main:
    let wild = Span { items: 4096 as *const i32, n: 1 }
    print(f"{span_first_v(wild)}")
