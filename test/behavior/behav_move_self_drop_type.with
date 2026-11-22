//! expect-stdout: v=42 drops=1
// §9.5: `move self: Self` consumes — the receiver drops in the callee; nothing
// remains for the caller's scope exit.
var DROPS = 0
type Token { id: i32 }
impl Drop for Token:
    fn drop(move self: Self): DROPS = DROPS + 1
fn Token.consume(move self: Self) -> i32:
    self.id * 2
fn main:
    let t = Token { id: 21 }
    let v = t.consume()
    print(f"v={v} drops={DROPS}")
