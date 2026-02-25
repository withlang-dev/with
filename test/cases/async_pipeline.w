// Test: Async chaining with multiple awaits
async fn compute(x: i32) -> i32 = x * 2

async fn chain(x: i32) -> i32 =
    let a = compute(x).await
    let b = compute(a).await
    b

fn main() -> i32 =
    let result = chain(5).await
    // 5 * 2 = 10, 10 * 2 = 20
    if result == 20 then 0 else 1
