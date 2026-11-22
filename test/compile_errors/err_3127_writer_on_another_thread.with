//! expect-check-fail: E0921: call of `my_setenv` may race: it rewrites `vars`, process state a view is taken of
//! expect-check-fail: program may run concurrently here
//! expect-check-fail: `my_setenv`, which rewrites `vars`, is called from code that may run off `main`'s own path

// #3127, D208 (§16.2b.7), Eric's first acceptance program: one thread holds
// a view of the environment text while another calls the function that
// rewrites it. The writer returns no view; the race is with the holder.
use c_import("static char env_text[32];\nstatic inline const char *my_getenv(void) { return env_text; }\nstatic inline int my_setenv(int c) { env_text[0] = (char)c; env_text[1] = 0; return 0; }\n")

c contract env:
    runs no threads
    domain vars process written by my_setenv
    fn my_getenv
        returns borrow CStr from domain vars

async fn other() -> i32: my_setenv(0x61)

fn main:
    let held = my_getenv()
    let t = other()
    print(f"{held.is_some()} {t.await}")
