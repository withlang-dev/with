// Test: Vec iteration with index tracking and complex logic
fn main() -> i32 =
    let v = Vec.of(10, 20, 30, 40, 50)

    // Sum using for-in
    var sum: i32 = 0
    for x in v:
        sum += x
    assert(sum == 150)

    // Manual indexed access loop
    var idx: i32 = 0
    var weighted_sum: i32 = 0
    while idx < v.len():
        let val = v.get(idx)
        weighted_sum += val * (idx + 1)
        idx += 1
    // 10*1 + 20*2 + 30*3 + 40*4 + 50*5 = 10+40+90+160+250 = 550
    assert(weighted_sum == 550)

    // Build a second vec from first, collecting only even-indexed elements
    var v2 = Vec.new()
    var i: i32 = 0
    while i < v.len():
        if i % 2 == 0:
            v2.push(v.get(i))
        i += 1
    assert(v2.len() == 3)
    assert(v2.get(0) == 10)
    assert(v2.get(1) == 30)
    assert(v2.get(2) == 50)

    // Pop elements and verify order
    let last = v2.pop()
    assert(last.is_some())
    assert(last.unwrap() == 50)
    assert(v2.len() == 2)

    let mid = v2.pop()
    assert(mid.unwrap() == 30)
    assert(v2.len() == 1)

    println("all vec_for_indexed tests passed")
    0
