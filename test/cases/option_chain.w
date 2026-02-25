// Test: Option chaining with map, and_then, filter combined
fn double(x: i32) -> i32 = x * 2
fn add_ten(x: i32) -> i32 = x + 10
fn is_even(x: i32) -> bool = x % 2 == 0

fn safe_div(x: i32) -> ?i32 =
    if x == 0 then None else Some(100 / x)

fn safe_sqrt_approx(x: i32) -> ?i32 =
    if x < 0 then None
    else if x == 0 then Some(0)
    else if x < 4 then Some(1)
    else if x < 9 then Some(2)
    else if x < 16 then Some(3)
    else Some(4)

fn main() -> i32 =
    // Chain map calls
    let a: ?i32 = Some(5)
    let b = a.map(double)
    let c = b.map(add_ten)
    assert(c.is_some())
    assert(c.unwrap() == 20)

    // Chain map on None
    let d: ?i32 = None
    let e = d.map(double)
    let f = e.map(add_ten)
    assert(f.is_none())

    // and_then chain
    let g: ?i32 = Some(5)
    let h = g.and_then(safe_div)
    assert(h.is_some())
    assert(h.unwrap() == 20)

    let h2 = h.and_then(safe_sqrt_approx)
    assert(h2.is_some())
    assert(h2.unwrap() == 4)

    // and_then returning None
    let j: ?i32 = Some(0)
    let k = j.and_then(safe_div)
    assert(k.is_none())

    // Filter passing
    let l: ?i32 = Some(4)
    let m = l.filter(is_even)
    assert(m.is_some())
    assert(m.unwrap() == 4)

    // Filter failing
    let n: ?i32 = Some(3)
    let o = n.filter(is_even)
    assert(o.is_none())

    // unwrap_or on chain result
    let p: ?i32 = None
    let q = p.map(double).unwrap_or(99)
    assert(q == 99)

    let r: ?i32 = Some(7)
    let s = r.map(double).unwrap_or(99)
    assert(s == 14)

    println("all option_chain tests passed")
    0
