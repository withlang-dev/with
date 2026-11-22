//! expect-error: unknown method 'incr'

// §16.2a: no_methods: "Counter" suppresses auto-methods for that type only.

use c_import("typedef struct Counter { int n; } Counter;\nstatic inline void counter_incr(Counter *c) { c->n = c->n + 1; }\n", no_methods: "Counter")

fn main:
    var c = Counter { n: 0 }
    c.incr()
    print("x")
