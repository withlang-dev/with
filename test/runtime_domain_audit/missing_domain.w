//! expect-violation: does not declare `domain locale process`
// runtime-domain-audit negative fixture (ruling §33-§36, §52): a facade whose
// rows are complete but which leaves one of the three libc domains
// undeclared — its rows then say nothing about that domain at all.

@[import_module("wasi_snapshot_preview1")]
extern fn fd_write(fd: i32, iovs: *const u8, iovs_len: i32, nwritten: *mut i32) -> i32

c facade wasi:
    domain errno thread
    domain environ process
    fn fd_write
