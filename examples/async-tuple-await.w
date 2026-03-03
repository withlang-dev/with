async fn fetch_user -> i32:
    7

async fn fetch_posts -> i32:
    3

fn main -> i32:
    let _pair = (fetch_user(), fetch_posts()).await
    0
