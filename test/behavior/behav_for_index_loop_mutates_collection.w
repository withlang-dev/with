//! expect-stdout: 6
//! expect-stdout: 7
//! expect-stdout: 2
//! expect-stdout: 3
//! expect-stdout: 8

// #1317: the loop-binding borrow fires only when the binding is a view into
// the collection being mutated. An index loop binds an i32, not a view, so
// every shape migrated C uses to walk and grow a buffer stays accepted: a
// range over `xs.len()` (evaluated once), a bounded `while` over an index,
// and reading `xs[j]` in the same iteration that pushes — as the pushed
// argument, through a Copy-annotated binding, or through a view whose last
// use precedes the push.

fn main:
    var xs: Vec[i32] = Vec.new()
    xs.push(1)
    xs.push(2)
    xs.push(3)
    for i in 0..xs.len():
        xs.push(i as i32)
    print(f"{xs.len()}")

    var ys: Vec[i32] = Vec.new()
    ys.push(7)
    var i = 0
    while i < ys.len() and i < 6:
        ys.push(1)
        i += 1
    print(f"{ys.len()}")

    var zs: Vec[i32] = Vec.new()
    zs.push(2)
    zs.push(3)
    for j in 0..2:
        zs.push(zs[j])
    for j in 0..2:
        let v: i32 = zs[j]
        zs.push(v)
    for j in 0..2:
        let v = zs[j]
        print(f"{v}")
        zs.push(1)
    print(f"{zs.len()}")
