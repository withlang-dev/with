//! expect-stdout: 0 3
//! expect-stdout: 1 4
//! expect-stdout: quiet
// #3077: `Enumerated.next` (std) is checked on demand from this `for`, a
// statement. Its tail `match` inherited the statement position and its
// `None` arm, checked with no demand, resolved to this program's
// `Mode.None`: "return type mismatch" inside the standard library.
enum Mode { None, Loud }
fn name(m: Mode) -> str:
    match m:
        .None => "quiet"
        .Loud => "loud"
fn main:
    let xs = [3, 4]
    var m = Mode.Loud
    for (i, x) in xs.enumerate(): print(f"{i} {x}")
    if m == Mode.Loud: m = Mode.None
    print(name(m))
