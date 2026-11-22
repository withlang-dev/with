//! expect-error: `pick` returns a view of the global `HIDDEN`, which its `from` clause does not name: the clause states every origin of the returned view (§21.1 rule 6)

// #1903 (§21.1 rule 6): a `from` clause states every origin; one that leaves
// out a global the body returns a view of is narrower than the view.

var HIDDEN: List[i32] = List.new()

fn pick(p: &List[i32], c: bool) -> &i32 from p:
    if c: &p[0] else: &HIDDEN[0]

fn main:
    HIDDEN.push(41)
    let x: List[i32] = List.new()
    print(*pick(&x, false))
