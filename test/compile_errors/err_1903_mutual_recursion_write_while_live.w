//! expect-check-fail: cannot mutate `G` while `r` is a live view into it

// #1903 (§21.1 rule 6): `up` and `down` call each other; the globals their
// returned views view are the least sets closed under their calls ({G} for
// both), computed by fixpoint whatever order their bodies are checked in.
// No `from` is needed; a write of G while `up`'s view is live is refused.

var G: List[i32] = List.new()

fn down(n: i32) -> &i32:
    if n == 0: &G[0] else: up(n - 1)

fn up(n: i32) -> &i32: down(n)

fn main:
    G.push(1)
    let r = up(3)
    G.push(2)
    print(*r)
