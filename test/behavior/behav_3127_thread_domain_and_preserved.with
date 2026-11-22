//! expect-stdout: true true true

// #3127, D208 (§16.2b.7): what the rule leaves alone. A thread domain's
// buffer is each thread's own; under 'written by any' a function that
// states 'preserves domain' is no writer.
use c_import("static inline const char *lib_version(void) { static char out[32]; out[0] = 0x76; out[1] = 0x31; out[2] = 0; return out; }\nstatic inline const char *lib_name(void) { return \"lib\"; }\nstatic inline int lib_work(int x) { return x * 2; }\n")

c contract lib:
    domain per_thread thread
    domain names process written by any
    fn lib_version
        returns borrow CStr from domain per_thread
        preserves domain names
    fn lib_name
        returns borrow CStr from domain names
        preserves domain names

async fn other() -> bool: lib_version().is_some()

fn main:
    let t = other()
    let mine = lib_version().is_some()
    let n = lib_name()
    print(f"{mine} {n.is_some()} {t.await}")
