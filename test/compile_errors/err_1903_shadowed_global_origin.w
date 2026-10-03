//! expect-error: the view `first` returns views the global `HIDDEN`, which a local binding shadows here: the call's result cannot be tied to the global (§21.1 rule 6)

// #1903 (§21.1 rule 6): a call's result views the private global HIDDEN of
// another module, which a local of the caller shadows: the tie cannot be
// made, so the call is refused, never left untied.

use issue1903.hidden
fn main:
    seed(41)
    let HIDDEN = 3
    let x: Vec[i32] = Vec.new()
    let r = first(&x)
    grow()
    print(*r + HIDDEN)
