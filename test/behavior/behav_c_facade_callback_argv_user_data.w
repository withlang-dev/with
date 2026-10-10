//! expect-stdout: registered 0
//! expect-stdout: step: 3 argument(s), sum 12, scale 2 (doubling)
//! expect-stdout: step: 0 argument(s), sum 0, scale 2 (doubling)
//! expect-stdout: fin: doubling
//! expect-stdout: run returned 25
//! expect-stdout: scale doubling destroyed
//! expect-stdout: registered 0
//! expect-stdout: step: 3 argument(s), sum 12, scale 3 (tripling)
//! expect-stdout: step: 0 argument(s), sum 0, scale 3 (tripling)
//! expect-stdout: run returned 36
//! expect-stdout: ok
//! expect-stdout: scale tripling destroyed

// Spec §16.2b.9 (D76, ruling Amendment 2, #1779): "A clause on the
// registering function may present a callback's argument vector as a slice
// of a callback-scope handle (`argv paired with argc as &[Value]`) and its
// registered user data as the value the facade boxed (`user_data as &U`).
// The compiler generates the wrapper; both are valid for the callback's
// invocation only."
//
// The engine below has SQLite's shape: registration consumes the userdata
// with a destroy callback, the step callback receives `(ctx *, int, val **)`
// and the final one `(ctx *)`, and the userdata comes back only through
// `ctx_user_data(ctx)`. The program's callbacks read their arguments as
// `&[Arg]` and the data as `&Scale` with no `unsafe`: every argument of a
// vector C passes (3, 4, 5), an empty vector C passes as NULL with count 0,
// a final callback with no vector, a callback the program does not give
// (C gets NULL, and calls nothing), and the data destroyed once by C —
// when a registration replaces it, and when the engine is freed.

use c_import("#include <stdlib.h>
typedef struct ctx { int acc; void *ud; } ctx;
typedef struct val { int n; } val;
typedef struct eng { void *ud; void (*step)(ctx *, int, val **); void (*fin)(ctx *); void (*destroy)(void *); } eng;
static inline eng *eng_new(void) { return (eng *)calloc(1, sizeof(eng)); }
static inline void eng_free(eng *e) { if (e->destroy) e->destroy(e->ud); free(e); }
static inline int eng_register(eng *e, void *ud, void (*step)(ctx *, int, val **), void (*fin)(ctx *), void (*destroy)(void *)) {
    if (e->destroy) e->destroy(e->ud);
    e->ud = ud; e->step = step; e->fin = fin; e->destroy = destroy;
    return 0;
}
static inline int eng_run(eng *e) {
    ctx c; c.acc = 0; c.ud = e->ud;
    val a = {3}, b = {4}, d = {5};
    val *argv[3] = {&a, &b, &d};
    if (e->step) { e->step(&c, 3, argv); e->step(&c, 0, NULL); }
    if (e->fin) e->fin(&c);
    return c.acc;
}
static inline void *ctx_user_data(ctx *c) { return c->ud; }
static inline void ctx_add(ctx *c, int v) { c->acc += v; }
static inline int val_get(val *v) { return v->n; }
")

c facade engines:
    resource Engine wraps *mut eng
        from eng_new
        drop eng_free
    handle Tally wraps *mut ctx
    handle Arg wraps *mut val
    fn eng_register
        consumes param ud destroyed_by param destroy
        retains param step by param 0
        retains param fin by param 0
        // D102 (§16.2b.8): C takes NULL for `fin`; the facade says so.
        nullable param fin
        callback param step argv param 2 paired with argc param 1 as &[Arg]
        user_data from ctx_user_data as &U
    fn eng_run
        lend
    fn ctx_add
        of Tally
    fn val_get
        of Arg

type Scale { k: i32, label: str }
impl Drop for Scale:
    move fn drop(): print(f"scale {self.label} destroyed")

fn step(t: Tally, args: &[Arg], s: &Scale):
    var sum: i32 = 0
    for i in 0..args.len() as i32:
        sum = sum + args[i].get()
    print(f"step: {args.len()} argument(s), sum {sum}, scale {s.k} ({s.label})")
    t.add(sum * s.k)

fn fin(t: Tally, s: &Scale):
    print(f"fin: {s.label}")
    t.add(1)

fn main:
    let e = Engine.new().unwrap()
    print(f"registered {e.register(Scale { k: 2, label: "doubling" }, step, Some(fin))}")
    print(f"run returned {e.run()}")
    // The second registration replaces the first, whose data C destroys.
    print(f"registered {e.register(Scale { k: 3, label: "tripling" }, step, None)}")
    print(f"run returned {e.run()}")
    print("ok")
