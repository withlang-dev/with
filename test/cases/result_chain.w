// Test: Result chaining with map, map_err, and_then, ok, err
fn double(x: i32) -> i32 = x * 2
fn negate(x: i32) -> i32 = 0 - x

fn validate(x: i32) -> Result[i32, i32] =
    if x > 0 then Ok(x) else Err(0 - x)

fn halve_if_even(x: i32) -> Result[i32, i32] =
    if x % 2 == 0 then Ok(x / 2) else Err(x)

fn main() -> i32 =
    // map chain on Ok
    let a: Result[i32, i32] = Ok(5)
    let b = a.map(double)
    assert(b.is_ok())
    assert(b.unwrap() == 10)
    let c = b.map(double)
    assert(c.unwrap() == 20)

    // map chain on Err propagates error
    let d: Result[i32, i32] = Err(3)
    let e = d.map(double)
    assert(e.is_err())
    let f = e.map(double)
    assert(f.is_err())

    // map_err transforms error value
    let g: Result[i32, i32] = Err(5)
    let h = g.map_err(negate)
    assert(h.is_err())

    // map_err on Ok passes through
    let i: Result[i32, i32] = Ok(42)
    let j = i.map_err(negate)
    assert(j.is_ok())
    assert(j.unwrap() == 42)

    // and_then chaining
    let k = validate(10)
    assert(k.is_ok())
    let l = k.and_then(halve_if_even)
    assert(l.is_ok())
    assert(l.unwrap() == 5)

    // and_then returning Err
    let m = validate(7)
    let n = m.and_then(halve_if_even)
    assert(n.is_err())

    // and_then on initial Err
    let o = validate(-3)
    assert(o.is_err())
    let p = o.and_then(halve_if_even)
    assert(p.is_err())

    // ok() and err() conversions
    let q: Result[i32, i32] = Ok(42)
    let r = q.ok()
    assert(r.is_some())
    assert(r.unwrap() == 42)

    let s: Result[i32, i32] = Err(99)
    let t = s.err()
    assert(t.is_some())
    assert(t.unwrap() == 99)

    let u = s.ok()
    assert(u.is_none())

    println("all result_chain tests passed")
    0
