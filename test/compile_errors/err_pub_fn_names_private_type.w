//! expect-check-fail: pub fn 'sleep_for' names private type 'Duration' in its signature; a public signature names only public types (§18.1)
// §18.1: every public declaration is reachable by name, so a `pub fn`
// cannot name a module-private type in its parameters or return type.
// (std.time's Duration and std.json's JsonParser shipped this way; #1150.)

pub fn sleep_for(d: Duration) -> i32:
    d

type Duration = i32

fn main:
    let _ = sleep_for(5)
