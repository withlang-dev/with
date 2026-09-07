async fn ready(value: i32) -> i32:
    value

type P { a: i32, b: i32 }

async fn m -> i32:
    let p = P { a: 10, b: 20 }
    let t = ready(0)
    p.{t.await as str}
