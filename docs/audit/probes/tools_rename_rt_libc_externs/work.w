// fixture: comment mentions open and _exit but must stay untouched
@[link_name("open")]
extern fn rt_libc_open(path: str) -> i32
extern fn with_helper() -> i32
extern fn rt_already() -> i32
@[link_name("_exit")]
extern fn rt_libc_exit(code: i32) -> i32

fn call_open(p: str):
    let s = "open and _exit stay in strings"
    rt_libc_open(p)
