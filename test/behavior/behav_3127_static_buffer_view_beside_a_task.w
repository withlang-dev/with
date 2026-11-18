//! expect-stdout: v1 7

// #3127, #3239, D208 (§16.2b.7, §16.3): a task that never reaches the
// domain's writer leaves the static-buffer call on main's own path.
use c_import("static inline const char *lib_version(void) { static char out[32]; out[0] = 0x76; out[1] = 0x31; out[2] = 0; return out; }\nstatic inline const char *lib_name(void) { return \"lib\"; }\nstatic inline int lib_work(int x) { return x * 2; }\n")

c contract lib:
    runs no threads
    domain lib_version process written by lib_version
    fn lib_version
        returns borrow CStr from domain lib_version

async fn work() -> i32: 7

fn main:
    let t = work()
    let v = lib_version().unwrap().to_str().unwrap().to_owned()
    print(f"{v} {t.await}")
