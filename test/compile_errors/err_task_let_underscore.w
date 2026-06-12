//! expect-error: not the detach spelling

async fn warm_cache() -> i32:
    42

fn main:
    let _ = warm_cache()
