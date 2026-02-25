// Test: Result combinator methods (map, map_err, and_then, ok, err)
fn double(x: i32) -> i32 = x * 2
fn negate(x: i32) -> i32 = 0 - x

fn main() -> i32 =
    // Result.map: Ok(5).map(double) == Ok(10)
    let a: Result[i32, i32] = Ok(5)
    let b = a.map(double)
    assert(b.is_ok())
    assert(b.unwrap() == 10)

    // Result.map on Err: Err(3).map(double) == Err(3)
    let c: Result[i32, i32] = Err(3)
    let d = c.map(double)
    assert(d.is_err())

    // Result.map_err: Err(3).map_err(negate) == Err(-3)
    let e: Result[i32, i32] = Err(3)
    let f = e.map_err(negate)
    assert(f.is_err())

    // Result.map_err on Ok: Ok(5).map_err(negate) == Ok(5)
    let g: Result[i32, i32] = Ok(5)
    let h = g.map_err(negate)
    assert(h.is_ok())
    assert(h.unwrap() == 5)

    // Result.ok: Ok(42).ok() == Some(42)
    let i: Result[i32, i32] = Ok(42)
    let j = i.ok()
    assert(j.is_some())
    assert(j.unwrap() == 42)

    // Result.ok on Err: Err(1).ok() == None
    let k: Result[i32, i32] = Err(1)
    let l = k.ok()
    assert(l.is_none())

    // Result.err: Err(7).err() == Some(7)
    let m: Result[i32, i32] = Err(7)
    let n = m.err()
    assert(n.is_some())
    assert(n.unwrap() == 7)

    // Result.err on Ok: Ok(1).err() == None
    let o: Result[i32, i32] = Ok(1)
    let p = o.err()
    assert(p.is_none())

    println("all result combinator tests passed")
    0
