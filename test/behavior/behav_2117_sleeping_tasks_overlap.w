//! expect-stdout: users posts
//! expect-stdout: ok
// #2117, §14.3: sleep suspends the task, not its thread. Of two tasks
// awaited together the one that sleeps less finishes first, whichever was
// started first; with a sleep that blocked the thread, the task that ran
// first finished first.
use std.time

async fn fetch(name: str, ms: i32) -> str:
    sleep(ms).await
    name

async fn woke_at(ms: i32) -> i64:
    sleep(ms).await
    now_ns()

fn main:
    let (users, posts) = (fetch("users", 30), fetch("posts", 30)).await
    print(f"{users} {posts}")
    let (late, early) = (woke_at(300), woke_at(20)).await
    assert(early < late)
    let (soon, later) = (woke_at(20), woke_at(300)).await
    assert(soon < later)
    print("ok")
