//! expect-check-fail: requires unsafe context

// §16.2a: without a facade the auto-method surface over a raw struct is
// the raw C call under another spelling; the compiler cannot prove the
// call, so it needs `unsafe`. The facaded program is
// behav_c_import_auto_method_baseline.w.

use c_import("typedef struct Counter { int n; } Counter;\nstatic inline void counter_incr(Counter *c) { c->n = c->n + 1; }\nstatic inline int counter_get(Counter *c) { return c->n; }\n")

fn main:
    var c = Counter { n: 0 }
    c.incr()
    let n = c.get()
    print(n)
