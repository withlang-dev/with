// Wave 6: chained if-let typing coverage.

fn a -> ?i32: Some(1)
fn b -> ?i32: Some(2)

fn main -> i32:
    let sum = if let Some(x) = a(), let Some(y) = b():
        x + y
    else
        0
    assert(sum == 3)
    sum
