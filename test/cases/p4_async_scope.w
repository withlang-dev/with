// Test: phase4 async scope tracked task behavior
async fn work() -> i32 = 1

fn main() -> i32 =
    async scope |s|:
        s.track(work())
    0
