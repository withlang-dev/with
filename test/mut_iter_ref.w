// Test: Vec.iter_ref() yields &T references

fn test_iter_ref_read:
    var xs = Vec.new()
    xs.push(10)
    xs.push(20)
    xs.push(30)
    var total = 0
    for x in xs.iter_ref():
        total = total + *x
    assert(total == 60)

fn test_iter_ref_no_copy:
    var xs = Vec.new()
    xs.push(1)
    xs.push(2)
    xs.push(3)
    xs.push(4)
    xs.push(5)
    var count = 0
    for x in xs.iter_ref():
        if *x > 2:
            count = count + 1
    assert(count == 3)

fn test_iter_ref_empty:
    var xs: Vec[i32] = Vec.new()
    var count = 0
    for x in xs.iter_ref():
        count = count + 1
    assert(count == 0)
