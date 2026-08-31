//! expect-stdout: ok

// D33 (#724): §13's consuming surface. `for x in vec.into_iter()` yields
// OWNED elements (the loop-shaped `remove`); the default `for x in vec:`
// stays a borrow (#712) and the source survives. Exhausting an empty
// iterator runs the body zero times.

type P { data: Vec[i32] }

fn head(p: &P): *p.data.get(0)

fn mk(n: i32) -> P:
    var d: Vec[i32] = Vec.new()
    d.push(n)
    P { data: d }

fn main:
    // owned transfer: elements land whole in the sink
    var xs: Vec[P] = Vec.new()
    xs.push(mk(1))
    xs.push(mk(2))
    xs.push(mk(3))
    var sink: Vec[P] = Vec.new()
    for p in xs.into_iter():
        sink.push(p)
    assert(sink.len() == 3)
    var total = 0
    for p in sink:
        total = total + p.data.get(0)
    assert(total == 6)

    // borrow default unchanged: source intact after the implicit form
    var ys: Vec[P] = Vec.new()
    ys.push(mk(7))
    for p in ys:
        assert(p.data.get(0) == 7)
    assert(ys.len() == 1)

    // empty source: zero iterations
    var es: Vec[P] = Vec.new()
    var count = 0
    for p in es.into_iter():
        count = count + 1
    assert(count == 0)

    // manual drive: next() transfers front-to-back, then None
    var zs: Vec[P] = Vec.new()
    zs.push(mk(21))
    zs.push(mk(22))
    var driver = zs.into_iter()
    var got = 0
    match driver.next():
        Some(p) => got = head(p)
        None => got = -1
    assert(got == 21)
    match driver.next():
        Some(p) => got = head(p)
        None => got = -1
    assert(got == 22)
    match driver.next():
        Some(p) => got = head(p)
        None => got = -1
    assert(got == -1)
    print("ok")
