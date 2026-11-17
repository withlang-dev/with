//! expect-check-fail: E0921: call of `lib_version` may race: it returns a view of `lib`, state the call itself rewrites
//! expect-check-fail: program may run concurrently here
//! expect-check-fail: = help: call it on the one thread that calls the library, or assert with `unsafe`

// #3127 (§16.2b.7): one thread holds the view while another makes the
// call that rewrites the buffer. 'Not Send' stops the view from moving;
// it does not stop the second call, so the call itself is refused.
use c_import("static inline const char *lib_version(void) { static char out[32]; out[0] = 0x76; out[1] = 0x31; out[2] = 0; return out; }\nstatic inline const char *lib_name(void) { return \"lib\"; }\n")

c contract lib:
    runs no threads
    domain lib process
    fn lib_version
        returns borrow CStr from domain lib

async fn other() -> i32:
    let again = lib_version()
    if again.is_some(): 1 else: 0

fn main:
    let held = lib_version()
    let t = other()
    print(f"{held.is_some()} {t.await}")
