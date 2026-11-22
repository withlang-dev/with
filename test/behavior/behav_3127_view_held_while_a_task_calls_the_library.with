//! expect-stdout: v1 42

// #3127, D208 (§16.2b.7), Eric's second acceptance program: main holds a
// view of the version text while a task calls another function of the
// library. Functions the domain does not name preserve it, so the task's
// call is no writer; the library's contract says its own threads do not
// rewrite the text.
use c_import("static inline const char *lib_version(void) { static char out[32]; out[0] = 0x76; out[1] = 0x31; out[2] = 0; return out; }\nstatic inline const char *lib_name(void) { return \"lib\"; }\nstatic inline int lib_work(int x) { return x * 2; }\n")

c contract lib:
    preserves domain lib_version
    domain lib_version process written by lib_version
    fn lib_version
        returns borrow CStr from domain lib_version

async fn work() -> i32: lib_work(21)

fn main:
    let held = lib_version()
    let t = work()
    let n = t.await
    print(f"{held.unwrap().to_str().unwrap()} {n}")
