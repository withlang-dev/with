// Test: collection combinators sequence/traverse on Vec

fn half_if_even(x: i32) -> ?i32 =
    if x % 2 == 0 then Some(x / 2) else None

fn nonneg(x: i32) -> Result[i32, i32] =
    if x < 0 then Err(99) else Ok(x)

fn main() -> i32 =
    var xo: Vec[?i32] = Vec.new()
    xo.push(Some(1))
    xo.push(Some(2))
    let so = xo.sequence()
    assert(so.is_some())
    let sov = so.unwrap()
    assert(sov.len() == 2)
    assert(sov.get(0) == 1)
    assert(sov.get(1) == 2)

    var xo2: Vec[?i32] = Vec.new()
    xo2.push(Some(1))
    xo2.push(None)
    assert(xo2.sequence().is_none())

    var xr: Vec[Result[i32, i32]] = Vec.new()
    xr.push(Ok(4))
    xr.push(Ok(5))
    let sr = xr.sequence()
    assert(sr.is_ok())
    let srv = sr.unwrap()
    assert(srv.len() == 2)
    assert(srv.get(0) == 4)
    assert(srv.get(1) == 5)

    var xr2: Vec[Result[i32, i32]] = Vec.new()
    xr2.push(Ok(1))
    xr2.push(Err(7))
    assert(xr2.sequence().is_err())

    var nums: Vec[i32] = Vec.new()
    nums.push(8)
    nums.push(6)
    let tv = nums.traverse(half_if_even)
    assert(tv.is_some())
    let tvv = tv.unwrap()
    assert(tvv.len() == 2)
    assert(tvv.get(0) == 4)
    assert(tvv.get(1) == 3)

    var nums2: Vec[i32] = Vec.new()
    nums2.push(8)
    nums2.push(7)
    assert(nums2.traverse(half_if_even).is_none())

    var nums3: Vec[i32] = Vec.new()
    nums3.push(1)
    nums3.push(2)
    let tr = nums3.traverse(nonneg)
    assert(tr.is_ok())
    let trv = tr.unwrap()
    assert(trv.len() == 2)
    assert(trv.get(0) == 1)
    assert(trv.get(1) == 2)

    var nums4: Vec[i32] = Vec.new()
    nums4.push(1)
    nums4.push(-1)
    assert(nums4.traverse(nonneg).is_err())

    var empty_o: Vec[?i32] = Vec.new()
    assert(empty_o.sequence().is_some())
    var empty_i: Vec[i32] = Vec.new()
    assert(empty_i.traverse(half_if_even).is_some())

    0
