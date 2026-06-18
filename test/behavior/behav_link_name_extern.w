//! expect-stdout: ok

// @[link_name("...")] lets an extern fn with a distinct With name link against
// a different C symbol. `my_strlen` resolves to libc `strlen`.

@[link_name("strlen")]
extern fn my_strlen(s: *const u8) -> u64

fn main:
    let n = unsafe { my_strlen(c"hello".ptr) }
    if n == 5:
        print("ok")
    else:
        print("bad")
