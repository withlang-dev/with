//! expect-check-fail: call to `grow` mutates global `HIDDEN` while `r` is a live view into it

// #1903 (§21.1 rule 6): `from G` names a global origin; a call that writes
// it while the result is live is refused.

var HIDDEN: Vec[i32] = Vec.new()

fn grow():
    for i in 0..1000: HIDDEN.push(i)

fn head() -> &i32 from HIDDEN: &HIDDEN[0]

fn main:
    HIDDEN.push(41)
    let r = head()
    grow()
    print(*r)
