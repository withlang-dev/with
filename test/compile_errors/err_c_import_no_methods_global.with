//! expect-error: unknown method 'incr'

// §16.2a: no_methods: true suppresses the auto-method surface, so the method
// form is a compile error while the flat function stays available.

use c_import("typedef struct Counter { int n; } Counter;\nstatic inline void counter_incr(Counter *c) { c->n = c->n + 1; }\n", no_methods: true)

fn main:
    var c = Counter { n: 0 }
    c.incr()
    print("x")
