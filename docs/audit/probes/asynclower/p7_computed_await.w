async fn ready(value: i32) -> i32:
    value

type P = struct { a: i32, b: i32 }

async fn m(key: str) -> i32:
    let p = P { a: 1, b: 2 }
    p.(key)
