//! expect-check-fail: takes `Span` by value, and field 'items'
// D198 (§16.2b.5): listing the function in a facade models nothing about the record; the call stays raw.
use c_import("typedef struct { const int *items; int n; } Span; static inline int span_first_v(Span s) { return s.n > 0 ? s.items[0] : 0; }")

c contract spans:
    fn span_first_v

fn main:
    let wild = Span { items: 4096 as *const i32, n: 1 }
    print(f"{span_first_v(wild)}")
