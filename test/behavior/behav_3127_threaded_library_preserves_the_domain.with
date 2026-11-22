//! expect-stdout: v1

// #3127, D208 (§16.2b.7): another linked library runs threads of its own.
// Its contract says those threads do not rewrite the version text, in one
// line for the whole library, so the view's call stays safe.
use c_import("static inline const char *lib_version(void) { static char out[32]; out[0] = 0x76; out[1] = 0x31; out[2] = 0; return out; }\nstatic inline const char *lib_name(void) { return \"lib\"; }\nstatic inline int lib_work(int x) { return x * 2; }\n")
use c_import("static inline int noisy_tick(int x) { return x + 1; }\n")

c contract lib:
    runs no threads
    domain lib_version process written by lib_version
    fn lib_version
        returns borrow CStr from domain lib_version

c contract noisy:
    runs threads
    preserves domain lib_version

fn main:
    let v = lib_version()
    print(v.unwrap().to_str().unwrap())
