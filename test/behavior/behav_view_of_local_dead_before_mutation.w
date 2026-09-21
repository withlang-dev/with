//! expect-stdout: 1 2 3

// #1249 / §21.1 rule 4 (NLL): a borrow of a local is active only up to its
// last use. Mutating the place after that use is legal, and a fresh borrow
// afterwards sees the new state.

type Box2 { n: i32 }

fn main:
    var v: Vec[str] = Vec.new()
    v.push("a".clone())
    let s = &v
    let n1 = s.len()
    v.push("b".clone())
    let t = &v
    let n2 = t.len()
    var b = Box2 { n: 3 }
    let r: &Box2 = b
    let n3 = r.n
    b.n = 4
    print(f"{n1} {n2} {n3}")
