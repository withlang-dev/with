// POSITIVE: disjoint field borrows should be allowed (§3.6)
type Obj = { left: i32, right: i32 }

fn main -> i32:
    let mut o = Obj { left: 1, right: 2 }
    let rl = &o.left
    let rmr = &mut o.right
    *rmr = 10
    assert(*rl == 1)
    assert(*rmr == 10)
    println("disjoint borrow ok")
