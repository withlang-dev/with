// T12 probe: infinite comptime loop must be LOUD (step-limit error), not a hang.
comptime fn hang() -> i32:
    while true:
        let x = 1
    0

fn main:
    let bad: i32 = comptime hang()
    assert(bad == 0)
