//! expect-stdout: 1 1 0 0 2

// #3060 (§4.3c rule 1): an empty `[]` waits for its first use; as one arm
// of an `if` expression that use is the join with the other arm. It was
// refused ("empty sequence literal requires expected type").
fn hosts(n: i32) -> List[i32]: [n]

fn pick(some: bool) -> List[i32]:
    let xs = if some: hosts(1) else: []
    xs

fn main:
    let a = if true: hosts(1) else: []
    let b = if false: [] else: hosts(2)
    let c = if false: hosts(3) else: []
    let d = if true: [] else: hosts(4)
    var e = if true: [] else: hosts(5)
    e.push(8)
    e.push(9)
    print(f"{a.len()} {b.len()} {c.len()} {d.len()} {e.len()}")
