// §16.7: std.ffi box/unbox round-trips a value through a type-erased context
// pointer. Drop runs exactly once — at the unboxed value's scope end (or at
// drop_ctx), never at box time. Recovery casts the erased pointer to *mut T.

use std.ffi

var FFI_TRACE = ""

type Payload { tag: str }

impl Drop for Payload:
    fn drop(move self: Self):
        FFI_TRACE = FFI_TRACE ++ self.tag

fn test_ffi_box_unbox_roundtrip:
    FFI_TRACE = ""
    let ctx = box_ctx(Payload { tag: "P" })
    assert(FFI_TRACE == "")              // box must not drop
    {
        let got = unsafe { unbox_ctx(ctx as *mut Payload) }
        assert(got.tag == "P")           // value preserved across the boundary
        assert(FFI_TRACE == "")          // still owned by `got`, not dropped yet
    }
    assert(FFI_TRACE == "P")             // dropped once, at `got`'s scope end

fn test_ffi_drop_ctx_runs_drop_once:
    FFI_TRACE = ""
    let ctx = box_ctx(Payload { tag: "D" })
    assert(FFI_TRACE == "")
    unsafe:
        drop_ctx(ctx as *mut Payload)
    assert(FFI_TRACE == "D")             // drop_ctx runs Drop exactly once

fn test_ffi_ctx_write_through_box:
    let ctx = box_ctx(Payload { tag: "M" })
    unsafe:
        let p = ctx as *mut Payload
        (*p).tag = "X"
        assert(ctx_ref(p).tag == "X")
        drop_ctx(p)
