//! expect-violation: presents a safe view over process-global state 'cwd' (a row borrows `from domain cwd`) without declaring it a domain
// runtime-domain-audit negative fixture (spec §16.2b.14, D76): process-global
// state "becomes a domain the first time a facade presents a safe view
// whose validity it decides". A facade presenting text borrowed from the
// working directory without declaring it a domain gives the view no origin
// the runtime's `chdir` could be seen to invalidate.

@[link_name("chdir")]
extern fn rt_libc_chdir(path: *const u8) -> i32
@[link_name("cwd_text")]
extern fn rt_libc_cwd_text() -> *const u8

c facade libc:
    domain errno thread
    domain environ process
    domain locale process
    fn rt_libc_chdir
        preserves domain environ
        preserves domain locale
    fn rt_libc_cwd_text
        returns borrow CStr from domain cwd
        preserves domain environ
        preserves domain locale
