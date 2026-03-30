//! expect-stdout: ok

var G: Vec[i32] = Vec.new()

fn main:
    G.push(7)
    let n = G.len()
    assert(n == 1)
    let x = G[0]
    assert(x == 7)

    G.push(9)
    assert(G.len() == 2)
    assert(G[1] == 9)

    print("ok")
