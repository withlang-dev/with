//! expect-stdout: ok

// #579: a match arm that consumes the owner and then RETURNS (diverges) must not
// make the fallthrough path treat the owner as moved. The only arm that moves `s`
// exits the function, so `s` is still live on the path that falls through.

type State { mode: i32 }
impl Drop for State:
    fn drop(move self: Self):
        let _ = self.mode

fn consume(s: State) -> i32: s.mode

fn step(s: State) -> i32:
    match s.mode:
        0 => return consume(s)   // moves s AND returns (diverges)
        _ => ()                  // fallthrough: s untouched
    s.mode                       // must compile: s is live here (#579)

fn main:
    let s = State { mode: 5 }
    let r = step(s)
    assert(r == 5)
    print("ok")
