// Test: Option/Result combinator methods (map, and_then, filter, ok, err)
fn double(x: i32) -> i32 = x * 2

fn safe_div(x: i32) -> ?i32 =
    if x == 0 then None else Some(x / 2)

fn is_positive(x: i32) -> bool = x > 0

fn main() -> i32 =
    // Option.map: Some(5).map(double) == Some(10)
    let a: ?i32 = Some(5)
    let b = a.map(double)
    assert(b.is_some())
    assert(b.unwrap() == 10)

    // Option.map on None: None.map(double) == None
    let c: ?i32 = None
    let d = c.map(double)
    assert(d.is_none())

    // Option.and_then: Some(10).and_then(safe_div) == Some(5)
    let e: ?i32 = Some(10)
    let f = e.and_then(safe_div)
    assert(f.is_some())
    assert(f.unwrap() == 5)

    // Option.and_then on None: None.and_then(safe_div) == None
    let g: ?i32 = None
    let h = g.and_then(safe_div)
    assert(h.is_none())

    // Option.and_then returning None: Some(0).and_then(safe_div) == None
    let i: ?i32 = Some(0)
    let j = i.and_then(safe_div)
    assert(j.is_none())

    // Option.filter: Some(5).filter(is_positive) == Some(5)
    let k: ?i32 = Some(5)
    let l = k.filter(is_positive)
    assert(l.is_some())
    assert(l.unwrap() == 5)

    // Option.filter failing: Some(-3).filter(is_positive) == None
    let m: ?i32 = Some(-3)
    let n = m.filter(is_positive)
    assert(n.is_none())

    // Option.filter on None: None.filter(is_positive) == None
    let o: ?i32 = None
    let p = o.filter(is_positive)
    assert(p.is_none())

    println("all option combinator tests passed")
    0
