//! expect-stdout: 20
//! expect-stdout: 30

// D63 (§12.4 "The callable type"): a `move ||` closure owns its environment,
// so a function may return one; the caller calls it after the creating
// frame is gone. Before D63 the environment was a slot of `mk`'s frame
// (#1567: garbage once `mk` was not inlined).
@[noinline]
fn mk(x: i32) -> fn() -> i32: move () => x * 10

fn main:
    let f = mk(2)
    let g = mk(3)
    print(f())
    print(g())
