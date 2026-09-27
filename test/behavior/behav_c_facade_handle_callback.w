//! expect-stdout: step 1: total=12 label=run
//! expect-stdout: step 2: total=16 label=run
//! expect-stdout: step 3: total=22 label=run
//! expect-stdout: run returned 22
//! expect-stdout: ok

// Spec §16.2b.9 (D71, ruling Amendment 1, #1611): a foreign representation
// that exists only for a callback's invocation is declared `handle Name
// wraps *mut T`. Nothing produces or destroys it and it has no Drop; the
// callback receives it borrowed for its scope (the `Tally` C passes each
// step), and the operations stated `of` it are its methods, so the body
// calls them with no `unsafe`: a lend (`add`), a lend through a const
// pointer (`total`), and a text view of the handle (`label`, a CStr that
// lives no longer than it). The callback's C type
// `void (*)(ctx *, int, void *)` is presented as
// `extern "C" fn(Tally, c_int, &U)`.

use c_import("#include <stdlib.h>
typedef struct ctx { int acc; const char *label; } ctx;
typedef struct eng { int base; } eng;
static inline eng *eng_new(int base) { eng *e = (eng *)malloc(sizeof(eng)); e->base = base; return e; }
static inline void eng_free(eng *e) { free(e); }
static inline int eng_run(eng *e, void (*cb)(ctx *c, int n, void *ud), void *ud) {
    ctx c; c.acc = e->base; c.label = \"run\";
    for (int i = 1; i <= 3; i++) cb(&c, i, ud);
    return c.acc;
}
static inline void ctx_add(ctx *c, int v) { c->acc += v; }
static inline int ctx_total(const ctx *c) { return c->acc; }
static inline const char *ctx_label(ctx *c) { return c->label; }
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
    fn ctx_total
        of Tally
    fn ctx_label
        of Tally
        returns borrow CStr from param 0

type Scale { k: i32 }

fn step(t: Tally, n: c_int, scale: &Scale):
    t.add(n * scale.k)
    print(f"step {n}: total={t.total()} label={t.label().unwrap().to_str().unwrap()}")

fn main:
    let e = Engine.new(10).unwrap()
    let total = e.run(step, Scale { k: 2 })
    print(f"run returned {total}")
    print("ok")
