//! expect-stdout: v1

// #3127 (§16.2b.7): a function that returns its own static buffer is a C
// global with a function in front of it. Its text is a view of the
// library's process domain, and the call is safe where every call into
// the library is on one thread and its contract says 'runs no threads'.
use c_import("static inline const char *lib_version(void) { static char out[32]; out[0] = 0x76; out[1] = 0x31; out[2] = 0; return out; }\nstatic inline const char *lib_name(void) { return \"lib\"; }\n")

c contract lib:
    runs no threads
    domain lib process
    fn lib_version
        returns borrow CStr from domain lib

fn main:
    let v = lib_version()
    print(v.unwrap().to_str().unwrap())
