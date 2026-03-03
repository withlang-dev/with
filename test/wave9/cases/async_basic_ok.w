async fn compute(x: i32) -> i32:
    x * 2 + 1

fn main -> i32:
    let task = compute(21)
    let result = task.await
    if result == 43 then 0 else 1
