//! expect-stdout: ok
// §16 / §16.2b.11 (D51 stage 8): a c_import factory function is a type-call
// constructor. Under a facade it constructs the resource (`Count.make(7)`
// for `counter_make`, ruling §54's prefix shortening), the returned pointer
// is owned by the resource and released by its `drop`, and the program
// needs no `unsafe`. Without a facade the raw `Counter.make(7)` keeps the
// call unsafe (err_c_import_auto_constructor_without_facade_is_raw.w).
use c_import("#include <stdlib.h>\ntypedef struct Counter { int n; } Counter;\nstatic inline Counter *counter_make(int v) { Counter *c = (Counter*)malloc(sizeof(Counter)); c->n = v; return c; }\nstatic inline int counter_get(const Counter *c) { return c->n; }\nstatic inline void counter_free(Counter *c) { free(c); }\n")

c facade counter:
    resource Count wraps *mut Counter
        from counter_make
        drop counter_free
    fn counter_get

fn main:
    let c = Count.make(7).unwrap()
    if c.get() == 7: print("ok")
    else: print("bad")
