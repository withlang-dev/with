// Test: async block lowering and await
fn main() -> i32 =
    let t = async:
        21 * 2
    let v = t.await
    if v == 42 then 0 else 1
