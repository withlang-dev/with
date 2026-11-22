//! expect-error: E0702

async fn work() -> i32:
    42

fn main:
    no_suspend:
        async scope s =>:
            let task = s.track(work())
            assert(1 == 1)
