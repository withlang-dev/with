//! expect-stdout: ok

fn free_impl(ptr: *mut u8, count: i32) -> i32:
    let _ = ptr
    count + 1

type MemCtl {
    free: *const fn(*mut u8, i32) -> i32,
    memory_data: i32,
}

type GContext {
    memctl: MemCtl,
}

fn main:
    var calls: i32 = 0
    let memctl = MemCtl { free: &free_impl, memory_data: calls }
    let gcontext = GContext { memctl }
    calls = gcontext.memctl.free(0 as *mut u8, gcontext.memctl.memory_data)
    assert(calls == 1)
    print("ok")
