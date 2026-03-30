//! expect-stdout: ok

enum Val { Num(i32) | Empty }

fn main:
    // Match on enum with payload in expression position (was crashing due to
    // bind_pattern confusing symbol IDs with node IDs in resolve pass)
    let x: Val = Num(42)
    let r = match x
        .Num(n) => n
        .Empty => 0
    assert(r == 42)

    let y = Empty
    let r2 = match y
        .Num(n) => n
        .Empty => -1
    assert(r2 == -1)

    // Option match in expression position
    let o: Option[i32] = Some(10)
    let v = match o
        .Some(n) => n
        .None => 0
    assert(v == 10)

    print("ok")
