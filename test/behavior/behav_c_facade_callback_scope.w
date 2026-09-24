//! expect-stdout: ok

// D51 stage 9 (ruling §44, spec §16.2b.9): a callback and its userdata
// handed to C for one call are borrowed for that call. `callback param 1
// userdata param 2` types the userdata: the method is `exec[U](cb: extern
// "C" fn(&U, c_int) -> c_int, ud: &U, n)`, the callback a captureless fn or
// closure (§12.4: C receives the code pointer alone), and the userdata any
// value — an ephemeral view included, since nothing outlives the call.
// Reentrancy (§47) is by construction: the callback reaches the resource
// only through a shared view it was given, so it can read, never mutate.
use c_import("c_facade_callbacks.h")

c facade dbc:
    resource Database wraps *mut db
        from db_new
        drop db_close
    fn db_exec
        callback param 1 userdata param 2
    fn db_total
        lend

type Ctx { base: i32 }
fn on(c: &Ctx, n: c_int) -> c_int: c.base + n

type View = ephemeral { db: &Database, base: i32 }
fn reenter(v: &View, n: c_int) -> c_int: v.db.total() + v.base + n

fn main:
    let l = log_new()
    if true:
        let d = Database.new(l, 1).unwrap()
        let ctx = Ctx { base: 100 }
        assert(d.exec(on, ctx, 1) == 101)
        assert(d.exec((c, n) => c.base * n, ctx, 2) == 200)
        assert(ctx.base == 100)
        let v = View { db: d, base: 1000 }
        assert(d.exec(reenter, v, 5) == 301 + 1000 + 5)
        assert(d.total() == 301 + 1306)
    assert(log_len(l) == 4)
    assert(log_at(l, 0) == 4001 and log_at(l, 1) == 4002 and log_at(l, 2) == 4005 and log_at(l, 3) == 2001)
    log_free(l)
    print("ok")
