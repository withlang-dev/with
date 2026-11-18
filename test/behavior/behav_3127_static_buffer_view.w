//! expect-stdout: v1

// #3127, D208 (§16.2b.7): a function that returns its own static buffer
// returns a view of a process domain it is the one writer of. Its call is
// safe where every call that rewrites or views the domain is on one thread
// and every linked contract says 'runs no threads' or preserves the domain.
use c_import("static inline const char *lib_version(void) { static char out[32]; out[0] = 0x76; out[1] = 0x31; out[2] = 0; return out; }\nstatic inline const char *lib_name(void) { return \"lib\"; }\nstatic inline int lib_work(int x) { return x * 2; }\n")

c contract lib:
    runs no threads
    domain lib_version process written by lib_version
    fn lib_version
        returns borrow CStr from domain lib_version

fn main:
    let v = lib_version()
    print(v.unwrap().to_str().unwrap())
