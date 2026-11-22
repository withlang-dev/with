// Spec test: Section 9.6 — Backward Application

fn double(x: i32) -> i32: x * 2
fn add1(x: i32) -> i32: x + 1

fn test_backward_basic:
    assert((double <| 5) == 10)

fn test_backward_chained_right_assoc:
    // add1(double(3)) = add1(6) = 7
    assert((add1 <| double <| 3) == 7)
