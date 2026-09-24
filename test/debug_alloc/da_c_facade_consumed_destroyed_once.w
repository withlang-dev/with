//! expect-debug-alloc: leak count=0
// D51 stage 9 (ruling §24; spec §16.2b.5, §16.2b.9) under the debug
// allocator: userdata consumed with a destroy callback is boxed by the
// rendered method, handed to C, and destroyed by C through the compiler's
// destroy fn — once: when C replaces it, and when the database closes on
// every path (scope end, early return, a Vec of databases). A userdata
// destroyed twice is a DOUBLE FREE; one never destroyed is a LEAK.
use c_import("../behavior/c_facade_callbacks.h")

c facade dbc:
    resource Database wraps *mut db
        from db_new
        drop db_close
    fn db_set_owned
        consumes param 1 destroyed_by param 2

type Ctx { log: Log, id: i32, text: str }
impl Drop for Ctx:
    move fn drop(): log_push(self.log, 1000 + self.id)

fn early(l: Log) -> i32:
    let d = Database.new(l, 2).unwrap()
    if d.set_owned(Ctx { log: l, id: 21, text: "early" }) == 2:
        return 1
    0

fn main:
    let l = log_new()
    if true:
        let d = Database.new(l, 1).unwrap()
        assert(d.set_owned(Ctx { log: l, id: 11, text: "first" }) == 2)
        assert(d.set_owned(Ctx { log: l, id: 12, text: "second" }) == 2)
    assert(log_len(l) == 5)
    assert(log_at(l, 1) == 1011 and log_at(l, 3) == 1012 and log_at(l, 4) == 2001)
    log_reset(l)
    assert(early(l) == 1)
    assert(log_len(l) == 3 and log_at(l, 1) == 1021)
    log_reset(l)
    if true:
        var all: Vec[Database] = Vec.new()
        for i in 1..4:
            let d = Database.new(l, 30 + i).unwrap()
            assert(d.set_owned(Ctx { log: l, id: 30 + i, text: "vec" }) == 2)
            all.push(d)
        assert(all.len() == 3)
    assert(log_len(l) == 9)
    log_free(l)
