// Test: async function can be called from sync function
async fn compute(x: i32) -> i32 =
    x * 2

fn helper(x: i32) -> i32 =
    let t = compute(x)
    t.await

fn main() -> i32 =
    assert(helper(21) == 42)
    0
