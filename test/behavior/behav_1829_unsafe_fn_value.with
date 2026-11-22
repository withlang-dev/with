//! expect-stdout: 2
//! expect-stdout: 3
//! expect-stdout: 11

// §16.11 (#1829): an `unsafe fn`, or a manual extern whose call needs
// `unsafe`, is an unsafe callable as a value; called under `unsafe`, or
// through an `unsafe fn` type, it runs.

unsafe fn danger(x: i32) -> i32: x + 1

extern "C" fn strlen(s: *const u8) -> usize

fn twice(g: unsafe fn(i32) -> i32, x: i32) -> i32: unsafe { g(g(x)) }

fn main:
    let f = danger
    print(unsafe { f(1) })
    print(twice(danger, 1))
    let len = strlen
    print(unsafe { len(c"hello world".ptr as *const u8) })
