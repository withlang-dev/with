//! expect-check-fail: requires unsafe context

// §16: without a facade a factory's type-call constructor returns a raw
// pointer nothing destroys; the call needs `unsafe`. The facaded program
// is behav_c_import_auto_constructor.w.

use c_import("#include <stdlib.h>\ntypedef struct Counter { int n; } Counter;\nstatic inline Counter *counter_make(int v) { Counter *c = (Counter*)malloc(sizeof(Counter)); c->n = v; return c; }\nstatic inline int counter_get(const Counter *c) { return c->n; }\n")

fn main:
    let c = Counter.make(7)
    print(unsafe { counter_get(c) })
