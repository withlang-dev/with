//! expect-check-fail: is both consumed ('consumes … destroyed_by': C owns and destroys it) and retained ('retains … by': the resource owns and releases it); state one
//! expect-check-fail: = help: keep 'consumes … destroyed_by' when C destroys the value, 'retains … by' when the resource releases it

// D51 stage 9 (spec §16.2b.5, §16.2b.9): one owner for a userdata — C
// (with a destroy callback) or the resource (retained) — never both.
use c_import("../behavior/c_facade_callbacks.h")

c contract dbc:
    resource Database wraps *mut db
        from db_new
        drop db_close
    fn db_set_owned
        consumes param 1 destroyed_by param 2
        retains param 1 by param 0

fn main:
    print("ok")
