//! expect-stdout: ok

fn free_impl(ptr: *mut u8, count: *mut i32):
    let _ = ptr
    unsafe:
        *count = *count + 1

type MemCtl {
    free: *const fn(*mut u8, *mut i32) -> void,
    memory_data: *mut i32,
}

type GContext {
    memctl: MemCtl,
}

fn main:
    var calls: i32 = 0
    let memctl = MemCtl { free: &free_impl, memory_data: &mut calls }
    let gcontext = GContext { memctl }
    gcontext.memctl.free(0 as *mut u8, gcontext.memctl.memory_data)
    assert(calls == 1)
    print("ok")
