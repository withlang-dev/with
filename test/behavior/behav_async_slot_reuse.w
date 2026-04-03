//! expect-stdout: ok

async fn work(n: i32) -> i32:
    n + 1

async fn main:
    var i = 0
    while i < 2048:
        let t = work(i)
        assert(t.await == i + 1)
        i = i + 1
    print("ok")
