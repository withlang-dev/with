//! expect-check-fail: thread.spawn_os captures non-Send value `s2`

// D51 stage 9 (ruling §50, spec §16.2b.10): `share` is independent of
// `send`. An Arc of a resource that is `share` but not `send` cannot move
// to another thread.
use c_import("../behavior/c_facade_callbacks.h")
use std.thread
use std.rc

c facade dbc:
    resource Database wraps *mut db
        from db_new
        drop db_close
        thread share

fn main:
    let l = log_new()
    let s = Arc.new(Database.new(l, 1).unwrap())
    let s2 = s.clone()
    let h = spawn_os(move () => { let mine = s2; 5 })
    print(f"{join(h)}")
