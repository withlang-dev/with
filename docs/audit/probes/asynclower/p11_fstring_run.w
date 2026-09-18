async fn ready(value: i32) -> i32:
    value

async fn main:
    let t = ready(41)
    print(f"v={t.await}")
