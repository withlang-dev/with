//! expect-stdout: ok

async fn side_effect() -> i32:
    0

async fn main:
    // spawn fire-and-forget: just ensure it doesn't crash
    spawn side_effect()
    print("ok")
