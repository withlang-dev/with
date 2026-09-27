//! expect-check-fail: this call stores a view of `t` into `keep` through its shared receiver, and `keep` outlives this call
//! expect-check-fail: 'Tally' is a callback-scope handle, borrowed for the callback's invocation, and cannot outlive it

// #1778 (§16.2b.9, §21.1): a callback-scope handle cannot outlive the
// callback. Stored through `Mutex.set` into the userdata — which outlives
// the callback — it would be a pointer into an invocation C has finished;
// the store is refused.
use std.sync
use c_import("#include <stdlib.h>
typedef struct ctx { int acc; } ctx;
typedef struct eng { int base; } eng;
static inline eng *eng_new(int base) { eng *e = (eng *)malloc(sizeof(eng)); e->base = base; return e; }
static inline void eng_free(eng *e) { free(e); }
static inline int eng_run(eng *e, void (*cb)(ctx *c, int n, void *ud), void *ud) { ctx c; c.acc = e->base; cb(&c, 1, ud); return c.acc; }
static inline void ctx_add(ctx *c, int v) { c->acc += v; }
")

c facade engines:
    resource Engine wraps *mut eng
        from eng_new
        drop eng_free
    handle Tally wraps *mut ctx
    fn eng_run
        callback param cb userdata param ud
    fn ctx_add
        of Tally

type Keeper = ephemeral { slot: Mutex[Option[Tally]] }

fn step(t: Tally, n: c_int, keep: &Keeper):
    keep.slot.set(Some(t))

fn main:
    let e = Engine.new(10).unwrap()
    let k = Keeper { slot: Mutex.new(None) }
    print(f"{e.run(step, k)}")
