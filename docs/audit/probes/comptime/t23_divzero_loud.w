// T23 probe: comptime arithmetic failure must be LOUD, not a silent wrong value.
comptime fn explode() -> i32:
    1 / 0

fn main:
    let bad: i32 = comptime explode()
    assert(bad == 0)
