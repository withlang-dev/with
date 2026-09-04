// T06 probe: I/O (runtime call) inside comptime fn must be LOUDLY rejected.
comptime fn noisy() -> i32:
    print("hi")
    0

fn main:
    let bad: i32 = comptime noisy()
    assert(bad == 0)
