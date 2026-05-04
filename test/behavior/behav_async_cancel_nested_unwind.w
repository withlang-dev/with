//! expect-stdout: ok

var seen: i32 = 0

async fn leaf() -> i32:
    7

async fn middle() -> i32:
    defer: seen = 1
    let t = leaf()
    t.await

async fn fast() -> i32:
    1

async fn main:
    seen = 0
    let slow = middle()
    let fast_t = fast()
    select await:
        x = fast_t => assert(x == 1)
        y = slow => assert(y == 7)
    assert(seen == 1)
    print("ok")
