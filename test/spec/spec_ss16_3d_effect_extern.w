//! expect-stdout: ok

@[effect(dst: write, src: read)]
extern "C" fn effect_memcpy(dst: *mut u8, src: *const u8, n: usize) -> *mut u8

@[effect(handle: consume)]
extern "C" fn effect_close_handle(handle: *mut u8) -> Unit

fn main:
    print("ok\n")
