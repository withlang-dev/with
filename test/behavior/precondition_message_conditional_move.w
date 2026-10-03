//! expect-stdout: consumed? no
//! expect-stdout: a
//! expect-stdout: kept
//! expect-stdout: drop a

// D86 (§18.2, #1864): a move inside the message operand is a conditional
// move, as in the right operand of `??`. The message runs only on the
// failing path, which does not return, so after the form the value is
// still owned here: it is usable, and dropped exactly once at scope end.
use std.testing

type Res:
    name: str
impl Drop for Res:
    move fn drop():
        print("drop " ++ self.name)

fn consume(r: Res) -> str:
    print("consumed? yes")
    r.name.clone()

fn main:
    let r = Res { name: "a" }
    require(true, consume(r))
    check(true, consume(r))
    assert(true, consume(r))
    testing.require(true, consume(r))
    print("consumed? no")
    print(r.name)
    let s = "kept".clone()
    testing.check(true, s)
    print(s)
