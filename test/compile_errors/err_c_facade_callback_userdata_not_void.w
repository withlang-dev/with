//! expect-check-fail: 'userdata param 3' names param 3: i32 n, which is not a 'void *'

// D51 stage 9 (spec §16.2b.9): a callback's userdata is the untyped pointer
// C hands back; naming another parameter is refused, with the resolved C
// parameter (§57).
use c_import("../behavior/c_facade_callbacks.h")

c facade dbc:
    resource Database wraps *mut db
        from db_new
        drop db_close
    fn db_exec
        callback param 1 userdata param 3

fn main:
    print("ok")
