// Audit probe: std.ffi box/ctx_ref/unbox/drop roundtrip (§16.7).
// Oracle: value preservation — boxed literals must read back identical, and
// Drop glue must run exactly once on the destroy path, never at box time.
use std.ffi.box_ctx
use std.ffi.unbox_ctx
use std.ffi.drop_ctx
use std.ffi.ctx_ref
use std.builtins.print

type State { count: i32 }

global var FFI_DROP_TRACE = ""

type FfiGuard { id: i32 }

impl Drop for FfiGuard:
    fn drop(move self: Self):
        FFI_DROP_TRACE = FFI_DROP_TRACE ++ "D"

fn destroy_state(ctx: *mut c_void):
    unsafe { drop_ctx(ctx as *mut State) }

fn main:
    // i32 roundtrip: box -> ctx_ref borrow -> unbox
    let p = box_ctx(41)
    let q = p as *mut i32
    unsafe:
        assert(*q == 41)
        let r = ctx_ref(q)
        assert(*r == 41)
    let v = unsafe { unbox_ctx(q) }
    assert(v == 41)
    // struct roundtrip
    let sp = box_ctx(State { count: 7 })
    let sq = sp as *mut State
    unsafe:
        assert(ctx_ref(sq).count == 7)
    let s = unsafe { unbox_ctx(sq) }
    assert(s.count == 7)
    // destroy-trampoline path (module-doc pattern)
    let dp = box_ctx(State { count: 9 })
    destroy_state(dp)
    // Drop runs exactly once on destroy, never at box time
    FFI_DROP_TRACE = ""
    let gp = box_ctx(FfiGuard { id: 1 })
    assert(FFI_DROP_TRACE == "")
    unsafe { drop_ctx(gp as *mut FfiGuard) }
    assert(FFI_DROP_TRACE == "D")
    print("ffi-roundtrip-ok")
