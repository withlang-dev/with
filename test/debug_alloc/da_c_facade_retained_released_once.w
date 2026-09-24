//! expect-debug-alloc: leak count=0
// D51 stage 9 (ruling §45; spec §16.2b.9) under the debug allocator: a
// retained callback's userdata is owned by the resource — boxed, handed to
// C as the pointer — and released after the resource is destroyed, once,
// on every path (scope end, early return, several registrations, a Vec of
// databases). Released twice is a DOUBLE FREE; never, a LEAK.
use c_import("../behavior/c_facade_callbacks.h")

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

type Ctx { log: Log, id: i32, text: str }
impl Drop for Ctx:
    move fn drop(): log_push(self.log, 1000 + self.id)
fn on(c: &Ctx, n: c_int) -> c_int: c.id + n

fn early(l: Log) -> i32:
    var d = Database.new(l, 2).unwrap()
    assert(d.register(on, Ctx { log: l, id: 21, text: "early" }) == 1)
    if d.fire(1) == 22:
        return 1
    0

fn main:
    let l = log_new()
    if true:
        var d = Database.new(l, 1).unwrap()
        assert(d.register(on, Ctx { log: l, id: 11, text: "first" }) == 1)
        assert(d.register(on, Ctx { log: l, id: 12, text: "second" }) == 1)
        assert(d.fire(1) == 13)
    assert(log_len(l) == 4)
    assert(log_at(l, 1) == 2001 and log_at(l, 2) == 1011 and log_at(l, 3) == 1012)
    log_reset(l)
    assert(early(l) == 1)
    assert(log_len(l) == 3 and log_at(l, 2) == 1021)
    log_reset(l)
    if true:
        var all: Vec[Database] = Vec.new()
        for i in 1..4:
            var d = Database.new(l, 30 + i).unwrap()
            assert(d.register(on, Ctx { log: l, id: 30 + i, text: "vec" }) == 1)
            all.push(d)
        assert(all.len() == 3)
    assert(log_len(l) == 6)
    log_free(l)
