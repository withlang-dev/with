//! expect-record: fn rt_libc_chdir (C symbol chdir): alters cwd
// runtime-domain-audit record fixture (spec §16.2b.14, D76, ruling
// Amendment 2, #1608): a seam altering process-global state no safe view
// reaches is clean — its row states only the libc domains — and the audit
// records the effect, keyed on the C symbol it links. A seam that only
// reads the state (getcwd) records nothing.

@[link_name("chdir")]
extern fn rt_libc_chdir(path: *const u8) -> i32
@[link_name("getcwd")]
extern fn rt_libc_getcwd(buf: *mut u8, size: u64) -> *mut u8

c facade libc:
    domain errno thread
    domain environ process
    domain locale process
    fn rt_libc_chdir
        preserves domain environ
        preserves domain locale
    fn rt_libc_getcwd
        preserves domain environ
        preserves domain locale
