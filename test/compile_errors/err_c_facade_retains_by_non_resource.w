//! expect-check-fail: 'retains … by' names param 3: i32 n, which receives no modeled resource

// D51 stage 9 (ruling §25, §45; spec §16.2b.5): retention is by a resource,
// and lasts until that resource is destroyed; `by` naming an int is refused.
use c_import("../behavior/c_facade_callbacks.h")

c facade dbc:
    resource Database wraps *mut db
        from db_new
        drop db_close
    fn db_exec
        retains param 2 by param 3

fn main:
    print("ok")
