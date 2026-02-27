// Test: advanced chained Option operations (map, and_then, filter, unwrap_or)
fn double(x: i32) -> i32: x * 2

fn safe_half(x: i32) -> ?i32:
    if x > 1 then Some(x / 2)
    else None

fn is_even(x: i32) -> bool: x % 2 == 0

fn main -> i32:
    // map then unwrap
    let a: ?i32 = Some(5)
    let b = a.map(double)
    assert(b.unwrap() == 10)

    // and_then chaining
    let c: ?i32 = Some(20)
    let d = c.and_then(safe_half)
    assert(d.is_some())
    assert(d.unwrap() == 10)

    // and_then returning None
    let e: ?i32 = Some(1)
    let f = e.and_then(safe_half)
    assert(f.is_none())

    // ?? default operator on Some
    let g: ?i32 = Some(42)
    assert(g ?? 0 == 42)

    // ?? default operator on None
    let h: ?i32 = None
    assert(h ?? 99 == 99)

    // unwrap_or
    let i: ?i32 = None
    assert(i.unwrap_or(55) == 55)

    // filter on Some matching
    let j: ?i32 = Some(4)
    let k = j.filter(is_even)
    assert(k.is_some())
    assert(k.unwrap() == 4)

    // filter on Some not matching
    let l: ?i32 = Some(3)
    let m = l.filter(is_even)
    assert(m.is_none())

    // is_some / is_none
    let n: ?i32 = Some(1)
    assert(n.is_some())
    assert(not n.is_none())
    let o: ?i32 = None
    assert(o.is_none())
    assert(not o.is_some())

    println("all option chain adv tests passed")
