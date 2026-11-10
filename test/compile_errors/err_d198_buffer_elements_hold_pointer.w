//! expect-check-fail: an element-count buffer's elements are flat, and field 'items'
// D198 (§16.2b.5, §16.2b.8): a slice of records that hold pointers hands C
// addresses safe code chose.
use c_import("typedef struct { const int *items; int n; } Span; static inline int spans_first(const Span *xs, int count) { return count > 0 && xs[0].n > 0 ? xs[0].items[0] : 0; }")

c facade spans:
    fn spans_first
        buffer param xs len param count elements

fn main:
    print("unreachable")
