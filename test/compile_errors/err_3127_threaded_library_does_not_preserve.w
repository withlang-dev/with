//! expect-check-fail: E0921: call of `lib_version` may race: it rewrites `lib_version`, process state a view is taken of
//! expect-check-fail: contract `noisy` says `runs threads` and does not say `preserves domain lib_version`: its threads may rewrite the state at any time

// #3127, D208 (§16.2b.7): the writer list protects against the program's
// calls, not against a linked library's own. A library that runs threads
// says in one line that they leave the state alone, or the call is raw.
use c_import("static inline const char *lib_version(void) { static char out[32]; out[0] = 0x76; out[1] = 0x31; out[2] = 0; return out; }\nstatic inline const char *lib_name(void) { return \"lib\"; }\nstatic inline int lib_work(int x) { return x * 2; }\n")
use c_import("static inline int noisy_tick(int x) { return x + 1; }\n")

c contract lib:
    runs no threads
    domain lib_version process written by lib_version
    fn lib_version
        returns borrow CStr from domain lib_version

c contract noisy:
    runs threads

fn main:
    let v = lib_version()
    print(v.is_some())
