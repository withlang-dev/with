// fixture: comment mentions open and _exit but must stay untouched
extern fn open(path: str) -> i32
extern fn with_helper() -> i32
extern fn rt_already() -> i32
extern fn _exit(code: i32) -> i32

fn call_open(p: str):
    let s = "open and _exit stay in strings"
    open(p)
