//! expect-violation: does not declare `domain cwd process`
// runtime-domain-audit negative fixture (#1608, ruling §35, §52): a facade
// that declares the three libc domains and all of the process state but the
// working directory — its rows then say nothing about the cwd at all, and a
// runtime call that began changing it would be invisible.

@[link_name("chdir")]
extern fn rt_libc_chdir(path: *const u8) -> i32

c facade libc:
    domain errno thread
    domain environ process
    domain locale process
    domain signals process
    domain signal_mask thread
    domain fds process
    domain rlimits process
    domain children process
    domain stdio process
    fn rt_libc_chdir
