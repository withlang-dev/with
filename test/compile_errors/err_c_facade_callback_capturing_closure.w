//! expect-check-fail: capturing closure cannot coerce to extern "C" fn pointer

// D51 stage 9 (spec §12.4, §16.2b.9): a facade callback is an extern "C"
// function pointer — C receives the code pointer alone — so only a
// captureless fn or closure is accepted; state lives in the userdata.
use c_import("../behavior/c_facade_callbacks.h")

c facade dbc:
    resource Database wraps *mut db
        from db_new
        drop db_close
    fn db_exec
        callback param 1 userdata param 2

type Ctx { base: i32 }

fn main:
    let l = log_new()
    let d = Database.new(l, 1).unwrap()
    let ctx = Ctx { base: 1 }
    let k = 5
    print(f"{d.exec((c, n) => c.base + n + k, ctx, 2)}")
