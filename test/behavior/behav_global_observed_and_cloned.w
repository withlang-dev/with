//! expect-stdout: 1 1 2 a

// #1242: reading, cloning and mutating a global in place stay legal; only a
// transfer out of it is rejected. The clone is an independent owner.

var g: Vec[str] = Vec.new()

fn snapshot() -> Vec[str]: g.clone()

fn first() -> &str: g.get(0)

fn main:
    g.push("a")
    let c = snapshot()
    let n = g.len()
    g.push("b")
    print(f"{c.len()} {n} {g.len()} {first()}")
