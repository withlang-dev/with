//! expect-check-fail: domain 'lib_text': a process domain says who rewrites it (§16.2b.7)
//! expect-check-fail: write 'domain lib_text process written by <fn>, <fn>', naming the functions that rewrite this state, or 'domain lib_text process written by any' when they are not known

// D208 (§16.2b.7): a process domain that names no writers would have no
// race check. It says 'written by f, g' or 'written by any'.
use c_import("static inline const char *lib_version(void) { static char out[32]; out[0] = 0x76; out[1] = 0x31; out[2] = 0; return out; }\nstatic inline const char *lib_name(void) { return \"lib\"; }\nstatic inline int lib_work(int x) { return x * 2; }\n")

c contract lib:
    runs no threads
    domain lib_text process
    fn lib_version
        returns borrow CStr from domain lib_text

fn main:
    print(lib_version().is_some())
