//! expect-check-fail: call to `P.add` mutates global `G` while `r` is a live view into it

// #1819 (§9.1c: globals are places; §21.1 rule 1): an operator is a call of its method (§11.7), and `add`
// writes G while an element view of G is live.
// A call writes every global its callee writes.

var G: List[str] = List.new()

type P { x: i32 }

impl Add[P, P] for P:
    fn add(self: &Self, rhs: &P) -> P:
        for i in 0..64: G.push(f"item{i}")
        P { x: self.x + rhs.x }

fn main:
    G.push("first" ++ "!")
    let r = G[0]
    let p = P { x: 1 } + P { x: 2 }
    print(f"{p.x}")
    print(r)
