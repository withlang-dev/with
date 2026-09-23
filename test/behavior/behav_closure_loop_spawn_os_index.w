//! expect-stdout: 600

// #1471: threads spawned in a loop each run with their own index. The
// `move` closure argument of `spawn_os` is created once per iteration; each
// copies the `for` binding at creation (§12.4: "`move ||` transfers
// ownership, which for a Copy value is a copy"). Before the fix all four
// closures shared one environment and every thread ran `run_once(3)`.
use std.thread

fn run_once(i: i32) -> i32: i * 100

fn main:
    var hs: Vec[JoinHandle] = Vec.new()
    for i in 0..4:
        hs.push(spawn_os(move () => run_once(i)))
    var sum = 0
    for k in 0..4:
        sum = sum + join(hs[k])
    print(sum)
