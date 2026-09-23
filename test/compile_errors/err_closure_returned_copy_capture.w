//! expect-check-fail: returned closure captures `x` by place

// #1567 / §12.4: captures are by place regardless of whether the type is
// Copy, so `() => x * 10` holds the parameter `x` by place — a view of
// this frame — and returning it is a view escape. (Before D62 this was a
// Copy snapshot in a frame slot that read garbage once `mk` was not
// inlined.) The owning form, `move () => x * 10`, waits on #1567.
fn mk(x: i32) -> fn() -> i32: () => x * 10

fn main:
    let f = mk(2)
    print(f())
