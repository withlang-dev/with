//! expect-check-fail: partial pattern on `E` inside its own `move fn` leaves payload 2 of `Running` unbound

// #1272: inside the enum's own `move fn` a variant pattern is the visible
// disarm of Drop and must be total; a `..` rest that skips payloads is an
// error naming the payloads left unbound.

var count: i32 = 0
enum E { Idle | Running(i32, i32) }
impl Drop for E:
    move fn drop(): count = count + 1
impl E:
    move fn pid() -> i32:
        match self:
            E.Running(p, ..) => p
            _ => -1

fn main:
    let e = E.Running(3, 4)
    print(f"{e.pid()}")
