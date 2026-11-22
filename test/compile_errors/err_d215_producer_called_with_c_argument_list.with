//! expect-check-fail: `it_init` takes 1 argument(s) here, found 2: the contract produces the `Iter`, so the parameter C fills is not passed

// D215: a producer called with the argument list from the C documentation
// gets an arity error that says what the contract did with the slot.
use c_import("typedef struct iter_s { int n; } iter_s;
static inline int it_init(iter_s* s, int base) { s->n = base; return 0; }
static inline void it_end(iter_s* s) { s->n = -1; }
")
c contract its:
    resource Iter wraps iter_s
        init it_init(self)
        drop it_end
fn main:
    var raw = iter_s.zeroed()
    let st = it_init(&raw mut raw, 1)
