//! expect-violation: has no `c facade` block
// runtime-domain-audit negative fixture (ruling §52): a runtime file that
// reaches foreign symbols — one by @[link_name], one by its bare C name —
// and carries no facade at all.

@[link_name("getenv")]
extern fn rt_libc_getenv(name: *const u8) -> *const u8
extern fn abort() -> Unit
extern fn rt_write(fd: i32, buf: *const u8, len: u64) -> i64
