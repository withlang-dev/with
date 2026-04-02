//! expect-stdout: ok

async fn compute(x: i32) -> i32:
    x * x

async fn main:
    async scope s =>:
        let t1 = compute(3)
        let t2 = compute(4)
        s.track(t1)
        s.track(t2)
    // Scope exit: all tracked tasks completed
    print("ok")
