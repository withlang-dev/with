// Test: if-let with Option types
fn find_positive(x: i32) -> ?i32 =
    if x > 0 then Some(x) else None

fn main() -> i32 =
    let result = find_positive(42)
    if let Some(v) = result:
        assert(v == 42)

    let result2 = find_positive(-5)
    if let Some(_) = result2:
        assert(false)

    0
