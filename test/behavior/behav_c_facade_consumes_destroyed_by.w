//! expect-stdout: ok

// D51 stage 9 (ruling §24, spec §16.2b.5, §16.2b.9): `consumes param 1
// destroyed_by param 2` moves the userdata into C, which destroys it
// through the callback the contract names — supplied by the compiler for
// the userdata's type, and withheld from the method: `set_owned[U](owned:
// U)`. With destroys it through no other path: the first value is destroyed
// when C replaces it, the second when the database closes (the log: C's
// destroy call, then the drop, each once).
use c_import("c_facade_callbacks.h")

c facade dbc:
    resource Database wraps *mut db
        from db_new
        drop db_close
    fn db_set_owned
        consumes param 1 destroyed_by param 2

type Ctx { log: Log, id: i32 }
impl Drop for Ctx:
    move fn drop(): log_push(self.log, 1000 + self.id)

fn main:
    let l = log_new()
    if true:
        let d = Database.new(l, 1).unwrap()
        assert(d.set_owned(Ctx { log: l, id: 1 }) == 2)
        assert(log_len(l) == 0)
        assert(d.set_owned(Ctx { log: l, id: 2 }) == 2)
        assert(log_len(l) == 2)
    assert(log_len(l) == 5)
    assert(log_at(l, 0) == 3001 and log_at(l, 1) == 1001)
    assert(log_at(l, 2) == 3001 and log_at(l, 3) == 1002 and log_at(l, 4) == 2001)
    log_free(l)
    print("ok")
