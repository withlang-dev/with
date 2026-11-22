//! expect-exit: 134
//! expect-stderr: fatal: fiber stack overflow (pulled generator)

// D69 (§13.4 Pulling, §14.19): a pulled generator runs on a pooled fiber
// stack with a guard page; overflowing it faults on the guard and is
// reported as a fiber stack overflow, never silent corruption.
fn deep(n: i64) -> i64:
    var pad: [64]i64 = [0 as i64; 64]
    pad[0] = n
    if n == 0: return 0
    deep(n - 1) + pad[0] - n + 1

gen fn blow(n: i64) -> i64:
    yield deep(n)

fn main:
    var p = blow(100000).pull()
    print(p.next().unwrap())
