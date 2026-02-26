// Test chained if-let syntax

fn get_a -> ?i32: Some(10)
fn get_b -> ?i32: Some(20)
fn get_none -> ?i32: None

fn main -> i32:
    // Single if-let
    if let Some(a) = get_a():
        assert(a == 10)

    // Chained if-let: both succeed
    if let Some(a) = get_a(), let Some(b) = get_b():
        assert(a + b == 30)

    // Chained if-let: first fails
    let x = if let Some(a) = get_none(), let Some(b) = get_b():
        a + b
    else
        99
    assert(x == 99)
