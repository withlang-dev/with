//! expect-check-fail: a value record is flat, and field 'inner.slots[]'
// D198 (§16.2b.5): flat means no pointer in any record, union or array inside it.
use c_import("typedef struct { const int *slots[2]; } Pair; typedef struct { int tag; Pair inner; } Outer; static inline void outer_fill(Outer *o) { o->tag = 1; o->inner.slots[0] = 0; o->inner.slots[1] = 0; }")

c contract outers:
    fn outer_fill
        fills param o

fn main:
    print("unreachable")
