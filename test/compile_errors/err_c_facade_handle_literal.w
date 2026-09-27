//! expect-check-fail: 'Tally' is a type the facade renders, and only its rendering makes one

// Spec §16.2b.9 (ruling Amendment 1, #1611): nothing produces a
// callback-scope handle but C, which passes it to the callback. A literal
// over a pointer the program chose would put that pointer under the
// handle's safe operations; it is refused.
use c_import("typedef struct ctx { int acc; } ctx;\nstatic inline void ctx_add(ctx *c, int v) { c->acc += v; }\n")

c facade engines:
    handle Tally wraps *mut ctx
    fn ctx_add
        of Tally

fn main:
    let t = Tally { repr: null }
    t.add(1)
