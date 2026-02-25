// Test: Option/Result expect(msg)
fn main() -> i32 =
    let o: ?i32 = Some(42)
    let r: Result[i32, i32] = Ok(7)

    assert(o.expect("missing value") == 42)
    assert(r.expect("unexpected error") == 7)
    0
