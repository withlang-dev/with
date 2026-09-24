//! expect-stdout: ok

// D51 stage 9 (ruling §45, spec §16.2b.9): a callback C keeps is modeled
// `retains … by param 0`, its userdata likewise. The userdata is owned by
// the resource from the call on — `register[U](cb, app: U)` takes it by
// value, a `mut fn` — and released after the resource is destroyed, exactly
// once (the log: fire, fire, close, then the drop). The callback is a code
// pointer; nothing is kept for it.
use c_import("c_facade_callbacks.h")

c facade dbc:
    resource Database wraps *mut db
        from db_new
        drop db_close
    fn db_register
        retains param 1 by param 0
        retains param 2 by param 0
        callback param 1 userdata param 2
    fn db_fire
        lend
    fn db_total
        lend

type Ctx { log: Log, id: i32, base: i32 }
impl Drop for Ctx:
    move fn drop(): log_push(self.log, 1000 + self.id)
fn on(c: &Ctx, n: c_int) -> c_int: c.base + n

fn main:
    let l = log_new()
    if true:
        var d = Database.new(l, 1).unwrap()
        assert(d.fire(1) == -1)
        assert(d.register(on, Ctx { log: l, id: 7, base: 10 }) == 1)
        assert(d.fire(1) == 11)
        assert(d.fire(2) == 12)
        assert(d.total() == 23)
    assert(log_len(l) == 4)
    assert(log_at(l, 0) == 4001 and log_at(l, 1) == 4002 and log_at(l, 2) == 2001 and log_at(l, 3) == 1007)
    log_free(l)
    print("ok")
