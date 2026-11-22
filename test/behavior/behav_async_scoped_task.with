//! expect-stdout: ok

async fn compute(x: i32) -> i32:
    x * 2

async fn main:
    async scope s =>:
        let t = s.track(compute(21))
        assert(t.await == 42)
        s.track(compute(1))
        0
    print("ok")
