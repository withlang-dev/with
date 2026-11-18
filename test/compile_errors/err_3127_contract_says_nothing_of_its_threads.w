//! expect-check-fail: E0921: call of `lib_version` may race: it rewrites `lib_version`, process state a view is taken of
//! expect-check-fail: contract `lib` says neither `runs no threads` nor `preserves domain lib_version` (§31.6.2: no default grant)
//! expect-check-fail: add `preserves domain lib_version` to its contract

// #3127, D208 (§16.2b.7, §31.6.2): no default grant. A library is not
// taken to run no threads, and its threads are not taken to leave the
// buffer alone; without either statement the call stays raw.
use c_import("static inline const char *lib_version(void) { static char out[32]; out[0] = 0x76; out[1] = 0x31; out[2] = 0; return out; }\nstatic inline const char *lib_name(void) { return \"lib\"; }\nstatic inline int lib_work(int x) { return x * 2; }\n")

c contract lib:
    domain lib_version process written by lib_version
    fn lib_version
        returns borrow CStr from domain lib_version

fn main:
    let v = lib_version()
    print(v.is_some())
