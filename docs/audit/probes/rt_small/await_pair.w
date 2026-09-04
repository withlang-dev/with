async fn fetch_a -> i32:
    7

async fn fetch_b -> i32:
    3

async fn async_main:
    let pair = (fetch_a(), fetch_b()).await
    print(f"await-ok user={pair.0} posts={pair.1}")

fn main:
    async_main()
