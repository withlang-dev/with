//! expect-stdout: local: 5
//! expect-stdout: guard swap: 6
//! expect-stdout: own view: 7
//! expect-stdout: owned: 9
//! expect-stdout: callback 1: 11
//! expect-stdout: ok

// #1778 (§21.1, D22): a view stored through `Mutex.set` is checked against
// the storage it lands in, and uses whose origins outlive that storage
// still compile: a local mutex declared after the local it views (set, and
// written back through `with m.enter_mut() as mut v`); a view
// of the receiver's own origin stored into the receiver; an owned value;
// and a callback-scope handle stored into a mutex local to the callback,
// which dies before the callback returns (§16.2b.9).
use std.sync
use c_import("#include <stdlib.h>
typedef struct ctx { int acc; } ctx;
typedef struct eng { int base; } eng;
static inline eng *eng_new(int base) { eng *e = (eng *)malloc(sizeof(eng)); e->base = base; return e; }
static inline void eng_free(eng *e) { free(e); }
static inline int eng_run(eng *e, void (*cb)(ctx *c, int n, void *ud), void *ud) { ctx c; c.acc = e->base; cb(&c, 1, ud); return c.acc; }
static inline void ctx_add(ctx *c, int v) { c->acc += v; }
static inline int ctx_total(const ctx *c) { return c->acc; }
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

type Pair = ephemeral { value: &i32, slot: Mutex[Option[&i32]] }

fn remember_own(p: &Pair):
    p.slot.set(Some(p.value))

type Scale { k: i32 }

fn step(t: Tally, n: c_int, s: &Scale):
    t.add(s.k)
    print(f"callback {n}: {t.total()}")
    let local: Mutex[Option[Tally]] = Mutex.new(None)
    local.set(Some(t))

fn main:
    let x = 5
    let six = 6
    let m: Mutex[Option[&i32]] = Mutex.new(None)
    m.set(Some(&x))
    with m.enter() as held:
        match held:
            Some(r) => print(f"local: {r}")
            None => print("none")
    with m.enter_mut() as mut v:
        v = Some(&six)
        print("swapping")
    with m.enter() as held:
        match held:
            Some(r) => print(f"guard swap: {r}")
            None => print("none")
    let seven = 7
    let p = Pair { value: &seven, slot: Mutex.new(None) }
    remember_own(p)
    with p.slot.enter() as held:
        match held:
            Some(r) => print(f"own view: {r}")
            None => print("none")
    let owned: Mutex[i32] = Mutex.new(0)
    owned.set(9)
    with owned.enter() as v: print(f"owned: {v}")
    let e = Engine.new(10).unwrap()
    let _ = e.run(step, Scale { k: 1 })
    print("ok")
