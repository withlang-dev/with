//! expect-stdout: ok

// §16.2a: no_methods: true disables auto-methods, but flat C functions
// remain callable (under unsafe, since they take raw pointers).

use c_import("typedef struct Counter { int n; } Counter;\nstatic inline void counter_incr(Counter *c) { c->n = c->n + 1; }\nstatic inline int counter_get(Counter *c) { return c->n; }\n", no_methods: true)

fn main:
    var c = Counter { n: 0 }
    unsafe:
        counter_incr(&raw mut c)
        counter_incr(&raw mut c)
    let n = unsafe { counter_get(&raw mut c) }
    if n == 2:
        print("ok")
    else:
        print("bad")
