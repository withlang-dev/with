//! expect-check-fail: the return type of 'later' was not known here

// #1196: neither function writes its return type and the callee is declared
// second, so the callee is not typed when the caller's body is checked.
fn twice(x: i32): later(x) + later(x)

fn later(x: i32): x * 21

fn main:
    let n: i32 = twice(1)
    print(f"{n}")
