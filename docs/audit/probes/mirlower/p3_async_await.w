async fn fetch_a -> i32:
    7

async fn fetch_b -> i32:
    3

async fn async_main:
    let v = fetch_a().await
    print(f"v={v}")
    let pair = (fetch_a(), fetch_b()).await
    print(f"a={pair.0} b={pair.1}")

fn main:
    async_main()
