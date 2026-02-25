// Test: select await — race two async tasks
async fn fast(x: i32) -> i32 =
    x * 10

async fn slow(x: i32) -> i32 =
    x * 100

fn main() -> i32 =
    let result = select await:
        a = fast(5) -> a
        b = slow(3) -> b
    println(result)
    0
