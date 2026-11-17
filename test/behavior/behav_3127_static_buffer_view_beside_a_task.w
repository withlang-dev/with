//! expect-stdout: v1 7

// #3127, #3239 (§16.2b.7, §16.3): a task that never reaches the library
// leaves the static-buffer call on main's own path.
use c_import("static inline const char *lib_version(void) { static char out[32]; out[0] = 0x76; out[1] = 0x31; out[2] = 0; return out; }\nstatic inline const char *lib_name(void) { return \"lib\"; }\n")

c contract lib:
    runs no threads
    domain lib process
    fn lib_version
        returns borrow CStr from domain lib

async fn work() -> i32: 7

fn main:
    let t = work()
    let v = lib_version().unwrap().to_str().unwrap().to_owned()
    print(f"{v} {t.await}")
