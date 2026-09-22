//! expect-stdout: ok

// D51 §16.2b.3: what the retired `owns: ["getcwd -> free"]` annotation said
// is a facade resource — a producer and the destroyer that releases what it
// produces. getcwd(NULL, 0) mallocs the cwd string; its buffer parameter is
// raw, so the producer the facade names is a C shim that passes NULL, and
// the resource's Drop frees the string exactly once (a second free aborts
// under the system allocator; `leaks --atExit` finds none left).

use c_import("char *getcwd(char *buf, unsigned long size);
void free(void *p);
static inline char *cwd_owned(void) { return getcwd(0, 0); }
")

c facade cwd:
    resource CwdString wraps *mut i8
        from cwd_owned
        drop free

fn main:
    match CwdString.cwd_owned():
        Some(cwd) =>
            if unsafe { *(cwd.repr as *const u8) } == 0u8:
                print("bad-empty")
            else:
                print("ok")
        None => print("bad-null")
