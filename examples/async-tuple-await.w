async fn fetch_user -> i32:
    7

async fn fetch_posts -> i32:
    3

async fn async_main:
    let _pair = (fetch_user(), fetch_posts()).await
    print("user={_pair.0} posts={_pair.1}")

fn main:
    async_main()
