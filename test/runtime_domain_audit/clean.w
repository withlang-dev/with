//! expect-clean
// runtime-domain-audit positive fixture (ruling §52): every foreign extern
// has a row, the runtime-internal externs (rt_*, with_*) need none, the
// LLVM intrinsic is not a foreign call, and comments inside the block are
// not rows.

@[link_name("write")]
extern fn rt_libc_write(fd: i32, buf: *const u8, len: u64) -> i64
@[link_name("__error")]
extern fn rt_libc_error() -> *mut i32
@[link_name("llvm.wasm.memory.size.i32")]
extern fn wasm_memory_size(mem: i32) -> i32
extern fn abort() -> Unit
extern fn rt_write(fd: i32, buf: *const u8, len: u64) -> i64
extern fn with_alloc(size: i64) -> *mut u8

c facade libc:
    // the three libc domains (ruling §33-§36)
    domain errno thread
    domain environ process
    domain locale process
    fn rt_libc_write
        preserves domain environ
        preserves domain locale
    fn rt_libc_error
        preserves domain errno
        preserves domain environ
        preserves domain locale
    fn abort
