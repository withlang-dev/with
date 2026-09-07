// T12 probe: infinite comptime recursion must be LOUD (recursion-limit error).
comptime fn recurse(n: i32) -> i32:
    recurse(n + 1)

fn main:
    let bad: i32 = comptime recurse(0)
    assert(bad == 0)
