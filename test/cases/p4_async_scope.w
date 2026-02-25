// Phase 4 gap: async scope task tracking syntax not implemented
async fn work() -> i32 = 1

fn main() -> i32 =
    async scope |s|:
        s.track(work())
    0
