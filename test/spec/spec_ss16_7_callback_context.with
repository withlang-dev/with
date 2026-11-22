//! expect-stdout: ok

// §16.7 Callback pattern: a C-shaped callback record (function pointer +
// type-erased `*mut c_void` context + destroy hook), with the context boxed
// and recovered through std.ffi. The callback bodies dereference the raw ctx,
// so they are `unsafe fn` and the slots are `unsafe extern "C" fn` (§16.11) —
// this is the spec example "modulo the documented trampoline pattern".

use std.ffi

var SS167_DROPS = 0

type State { count: i32 }

impl Drop for State:
    fn drop(move self: Self):
        SS167_DROPS = SS167_DROPS + 1

@[repr(C)]
type Callback {
    func: unsafe extern "C" fn(ctx: *mut c_void, arg: i32) -> i32,
    ctx: *mut c_void,
    destroy: unsafe extern "C" fn(ctx: *mut c_void) -> Unit,
}

// Per-type named trampolines (non-capturing → coerce to the fn-pointer slots).
// Each recovers the concrete type by casting the erased ctx; `T` is inferred.
unsafe fn cb_add(ctx: *mut c_void, arg: i32) -> i32:
    let p = ctx as *mut State
    (*p).count = (*p).count + arg
    (*p).count

unsafe fn cb_destroy(ctx: *mut c_void) -> Unit:
    drop_ctx(ctx as *mut State)

fn main:
    var ok = true
    let cb = Callback {
        func: cb_add,
        ctx: box_ctx(State { count: 10 }),
        destroy: cb_destroy,
    }
    // Boxing must not run the value's Drop.
    if SS167_DROPS != 0:
        ok = false
    unsafe:
        // Invoke through the C-shaped fn pointer; mutation persists across calls.
        let r1 = cb.func(cb.ctx, 5)
        if r1 != 15:
            ok = false
        let r2 = cb.func(cb.ctx, 100)
        if r2 != 115:
            ok = false
        // Immutable view sees the mutation.
        let v = ctx_ref(cb.ctx as *mut State)
        if v.count != 115:
            ok = false
        // destroy slot runs State's Drop exactly once and frees the box.
        cb.destroy(cb.ctx)
    if SS167_DROPS != 1:
        ok = false
    if ok:
        print("ok")
    else:
        print("bad")
