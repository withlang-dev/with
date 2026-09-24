//! expect-check-fail: an ephemeral value cannot be stored on the heap: it borrows stack-scoped storage (§5.1)

// D51 stage 9 (ruling §44-§45, spec §16.2b.9): a value borrowed for a call
// cannot be retained past it. A view (an ephemeral value) is accepted as
// callback-scope userdata (behav_c_facade_callback_scope) and refused as
// retained userdata, which the resource would own beyond the frame.
use c_import("../behavior/c_facade_callbacks.h")

c facade dbc:
    resource Database wraps *mut db
        from db_new
        drop db_close
    fn db_register
        retains param 1 by param 0
        retains param 2 by param 0
        callback param 1 userdata param 2
    fn db_total
        lend

type Ctx { base: i32 }
type View = ephemeral { ctx: &Ctx }
fn on(v: &View, n: c_int) -> c_int: v.ctx.base + n

fn main:
    let l = log_new()
    var d = Database.new(l, 1).unwrap()
    let ctx = Ctx { base: 1 }
    let v = View { ctx: ctx }
    print(f"{d.register(on, v)}")
