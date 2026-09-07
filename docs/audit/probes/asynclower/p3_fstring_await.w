async fn ready(value: i32) -> i32:
    value

async fn m:
    let t = ready(1)
    print(f"v={t.await}")
