// Spec test: Section 13.5 — Implicit Iteration
// Executable subset (vec! literals rewritten to Vec.new()+push).

fn test_for_in_auto_iter:
    let items: Vec[i32] = Vec.new()
    items.push(1)
    items.push(2)
    items.push(3)
    var sum = 0
    for x in items:
        sum = sum + x
    assert(sum == 6)
    assert(items.len() == 3)   // for-in does not consume the collection

fn test_explicit_iter:
    let items: Vec[i32] = Vec.new()
    items.push(1)
    items.push(2)
    var sum = 0
    for x in items.iter():
        sum = sum + x
    assert(sum == 3)

fn test_range_iteration:
    var sum = 0
    for i in 0..4:
        sum = sum + i
    assert(sum == 6)

fn test_for_loop_destructure:
    let pairs: Vec[(i32, str)] = Vec.new()
    pairs.push((1, "a"))
    pairs.push((2, "b"))
    var count = 0
    for (n, _s) in pairs:
        if n > 0: count = count + 1
    assert(count == 2)
