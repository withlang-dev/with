//! expect-stdout: ok

// Baseline: without no_methods, the auto-method surface is generated (calls
// go through the raw surface, so they require unsafe).

use c_import("typedef struct Counter { int n; } Counter;\nstatic inline void counter_incr(Counter *c) { c->n = c->n + 1; }\nstatic inline int counter_get(Counter *c) { return c->n; }\n")

fn main:
    var c = Counter { n: 0 }
    unsafe:
        c.incr()
    let n = unsafe { c.get() }
    if n == 1:
        print("ok")
    else:
        print("bad")
