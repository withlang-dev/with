async fn fetch_user(id: i32) -> i32:
    id * 10

async fn run:
    async scope s =>
        s.track(fetch_user(1))
        s.track(fetch_user(2))
        s.track(fetch_user(3))
    print("all tasks completed")

fn main:
    run()
