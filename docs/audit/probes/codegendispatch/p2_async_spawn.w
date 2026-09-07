async fn add_one(x: i32) -> i32:
    x + 1
fn main:
    let t = add_one(41)
    print(f"await={t.await}")
