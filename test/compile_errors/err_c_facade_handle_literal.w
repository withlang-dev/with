//! expect-check-fail: 'Tally' is a type the facade renders, and only its rendering makes one
//! expect-check-fail: = help: obtain it from the facade — its constructor, or the callback C invokes; raw access is the representation under the raw C rules (`unsafe`)

// Spec §16.2b.9 (ruling Amendment 1, #1611): nothing produces a
// callback-scope handle but C, which passes it to the callback. A literal
// over a pointer the program chose would put that pointer under the
// handle's safe operations; it is refused.
use c_import("typedef struct ctx { int acc; } ctx;\nstatic inline void ctx_add(ctx *c, int v) { c->acc += v; }\n")

c contract engines:
    handle Tally wraps *mut ctx
    fn ctx_add
        of Tally

fn main:
    let t = Tally { repr: null }
    t.add(1)
