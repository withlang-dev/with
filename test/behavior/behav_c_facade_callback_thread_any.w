//! expect-stdout: ok

// D51 stage 9 (ruling §51, spec §16.2b.10): `callback_thread any` says C
// may invoke the callback from any thread, so the userdata type must be
// Send and Sync — a struct of plain values is; a type holding an `Rc` is
// refused (err_c_facade_callback_thread_any_userdata_not_sync).
use c_import("c_facade_callbacks.h")

c facade dbc:
    resource Database wraps *mut db
        from db_new
        drop db_close
    fn db_exec
        callback param 1 userdata param 2
        callback_thread any

type Ctx { base: i32 }
fn on(c: &Ctx, n: c_int) -> c_int: c.base + n

fn main:
    let l = log_new()
    if true:
        let d = Database.new(l, 1).unwrap()
        let ctx = Ctx { base: 40 }
        assert(d.exec(on, ctx, 2) == 42)
    log_free(l)
    print("ok")
