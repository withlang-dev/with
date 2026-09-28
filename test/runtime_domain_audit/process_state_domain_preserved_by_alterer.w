//! expect-violation: fn rt_libc_chdir (C symbol 'chdir') states `preserves domain cwd`, but chdir alters cwd
// runtime-domain-audit negative fixture (spec §16.2b.14, D76, ruling §38,
// §52): once a safe view is presented over the working directory it is a
// domain, and the audit's record of which seams alter it decides the rows:
// `chdir` alters it, so a view borrowed from it does not survive the call,
// and a row saying it does is refused.

@[link_name("chdir")]
extern fn rt_libc_chdir(path: *const u8) -> i32
@[link_name("cwd_text")]
extern fn rt_libc_cwd_text() -> *const u8

c facade libc:
    domain errno thread
    domain environ process
    domain locale process
    domain cwd process
    fn rt_libc_chdir
        preserves domain environ
        preserves domain locale
        preserves domain cwd
    fn rt_libc_cwd_text
        returns borrow CStr from domain cwd
        preserves domain environ
        preserves domain locale
