//! expect-check-fail: a value record is flat, and field 'items'
// D198 (§16.2b.5): the callee follows a pointer the record holds, and safe
// code can set that field to any address; the clause is refused.
use c_import("typedef struct { const int *items; int n; } Span; static inline int span_first(const Span *s) { return s->n > 0 ? s->items[0] : 0; }")

c contract spans:
    fn span_first
        reads param s

fn main:
    print("unreachable")
