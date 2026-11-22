//! expect-check-fail: retention is modeled for a callback, its 'void *' userdata, and a C string
//! expect-check-fail: = help: delete the 'retains' clause and leave the function raw: no clause describes a kept pointer of another type (#3120)

// #3129 (§16.2b.9): what a resource can retain.
use c_import("../behavior/c_facade_callbacks.h")

c contract dbc:
    resource Database wraps *mut db
        from db_new
        drop db_close
    fn db_exec
        retains param 3 by param 0

fn main:
    print("unreachable")
