//! expect-check-fail: consumes param 1: *mut c_void owned, a 'void *' userdata, with no destroy contract

// D51 stage 9 (ruling §9, §24; spec §16.2b.5): userdata moved into C with
// no destroy callback would be owned by nothing that destroys it — never
// half-model unsafely.
use c_import("../behavior/c_facade_callbacks.h")

c facade dbc:
    resource Database wraps *mut db
        from db_new
        drop db_close
    fn db_set_owned
        consumes param 1

fn main:
    print("ok")
