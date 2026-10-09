//! expect-check-fail: call to `ping` mutates global `G` while `r` is a live view into it

// #1819 (§9.1c: globals are places; §21.1 rule 1): mutually recursive callees, one of which writes G.
// A call writes every global its callee writes.

var G: List[str] = List.new()

fn ping(n: i32):
    if n > 0: pong(n - 1)

fn pong(n: i32):
    G.push(f"p{n}")
    ping(n)

fn main:
    G.push("first" ++ "!")
    let r = G[0]
    ping(3)
    print(r)
