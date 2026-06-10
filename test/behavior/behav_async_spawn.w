//! expect-stdout: ok

async fn side_effect() -> i32:
    0

async fn main:
    assert(side_effect().await == 0)
    print("ok")
