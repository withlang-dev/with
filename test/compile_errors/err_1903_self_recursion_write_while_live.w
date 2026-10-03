//! expect-check-fail: cannot mutate `G` while `r` is a live view into it

// #1903 (§21.1 rule 6): `deep`'s own call reads its returned-view globals
// before its body has met `&G[0]`; the fixpoint completes the set ({G}), so
// `r` views G and `G.push(n)` under it is refused. No `from` is needed.

var G: Vec[i32] = Vec.new()

fn deep(n: i32) -> &i32:
    if n > 0:
        let r = deep(n - 1)
        G.push(n)
        r
    else: &G[0]

fn main:
    G.push(1)
    print(*deep(2))
