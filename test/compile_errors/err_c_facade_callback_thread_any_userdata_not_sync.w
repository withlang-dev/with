//! expect-check-fail: 'db_exec' may invoke its callback from any thread ('callback_thread any' in facade dbc), so the userdata type must be Send and Sync; 'Ctx' is neither Send nor Sync

// D51 stage 9 (ruling §51, spec §16.2b.10): under `callback_thread any`
// the userdata crosses threads with the callback, so its type must be
// Send and Sync; one holding an Rc is refused at the call.
use c_import("../behavior/c_facade_callbacks.h")
use std.rc

c facade dbc:
    resource Database wraps *mut db
        from db_new
        drop db_close
    fn db_exec
        callback param 1 userdata param 2
        callback_thread any

type Ctx { base: Rc[i32] }
fn on(c: &Ctx, n: c_int) -> c_int: n

fn main:
    let l = log_new()
    let d = Database.new(l, 1).unwrap()
    let ctx = Ctx { base: Rc.new(1) }
    print(f"{d.exec(on, ctx, 2)}")
