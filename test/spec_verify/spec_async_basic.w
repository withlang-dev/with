// POSITIVE: basic async/await (§14.4)
async fn compute(x: i32) -> i32:
    x * 2 + 1

fn main -> i32:
    let task = compute(21)
    let result = task.await
    assert(result == 43)
    println("async basic ok")
