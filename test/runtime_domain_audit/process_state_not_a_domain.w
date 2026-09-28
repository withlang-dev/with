//! expect-violation: 'cwd' is process-global state no safe view reaches: an effect the runtime audit records, not a domain
// runtime-domain-audit negative fixture (spec §16.2b.14, D76, ruling
// Amendment 2, #1608): the working directory is "an effect the runtime
// audit records, not a domain" while no safe view is presented over it. A
// runtime facade declaring it a domain states rows no view's validity
// depends on — the ceremony the ruling removed.

@[link_name("chdir")]
extern fn rt_libc_chdir(path: *const u8) -> i32

c facade libc:
    domain errno thread
    domain environ process
    domain locale process
    domain cwd process
    fn rt_libc_chdir
        preserves domain environ
        preserves domain locale
