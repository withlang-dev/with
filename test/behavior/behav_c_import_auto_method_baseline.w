//! expect-stdout: ok

// §16.2a / §16.2b.11 (D51 stage 8): the auto-method surface is presentation.
// Under a facade the methods land on the resource type, spelled by the same
// convention (`counter_incr` on `Count wraps Counter` is `c.incr()`), and
// the program needs no `unsafe`: the resource is the safe surface of the
// representation. Without a facade the raw struct's auto-methods stay raw
// and need `unsafe` (err_c_import_auto_method_without_facade_is_raw.w).

use c_import("typedef struct Counter { int n; } Counter;\nstatic inline void counter_init(Counter *c) { c->n = 0; }\nstatic inline void counter_end(Counter *c) { c->n = -1; }\nstatic inline void counter_incr(Counter *c) { c->n = c->n + 1; }\nstatic inline int counter_get(Counter *c) { return c->n; }\n")

c facade counter:
    resource Count wraps Counter
        init counter_init(self)
        drop counter_end
    fn counter_incr
    fn counter_get

fn main:
    var c = Count.init()
    c.incr()
    let n = c.get()
    if n == 1:
        print("ok")
    else:
        print("bad")
