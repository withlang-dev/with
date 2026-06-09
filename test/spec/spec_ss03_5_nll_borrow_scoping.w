//! check-only
// Spec test: §8.4 NLL view-liveness — accepted cases.
// Views expire at last use; mutation after last use is legal.

fn test_straight_line:
    var xs: Vec[i32] = Vec.new()
    xs.push(1)
    xs.push(2)
    let first = &xs[0]
    assert(*first == 1)
    // first is dead here — mutation allowed
    xs.push(3)

type Point { x: i32, y: i32 }

fn test_disjoint_fields:
    var p = Point { x: 1, y: 2 }
    let rx = &p.x
    // p.y is a disjoint field — mutation allowed
    p.y = 10
    assert(*rx == 1)

fn main:
    test_straight_line()
    test_disjoint_fields()
