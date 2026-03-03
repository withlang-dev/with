async fn work -> i32:
    41 + 1

fn main -> i32:
    let t = work()
    let r = t.await
    if r == 42 then 0 else 1

