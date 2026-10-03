//! expect-stdout: 7

// The #730 rejection must NOT fire for a Copy field read through a view:
// D22 rule 3 permits contextual Copy materialization.

type Outer { v: Vec[i32], n: i32 }

fn main:
    var o = Outer { v: Vec.new(), n: 7 }
    o.v.push(1)
    let r = &o
    let leaf = r.n
    print(int_to_string(leaf as i64))
