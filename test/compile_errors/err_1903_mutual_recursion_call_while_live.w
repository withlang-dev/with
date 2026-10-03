//! expect-check-fail: call to `grow` mutates global `G` while `r` is a live view into it

// #1903 (§21.1 rule 6): inside the cycle, `down`'s own call of `up` reads
// `up`'s globals before its body is done; the fixpoint completes them, so a
// call that writes G while that view is live is refused there too.

var G: Vec[i32] = Vec.new()

fn grow():
    for i in 0..1000: G.push(i)

fn down(n: i32) -> &i32:
    if n == 0: return &G[0]
    let r = up(n - 1)
    grow()
    r

fn up(n: i32) -> &i32: down(n)

fn main:
    G.push(1)
    print(*up(3))
