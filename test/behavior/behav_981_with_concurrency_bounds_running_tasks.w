//! expect-stdout: 36 25 16 9 4 1 | peak 2 | peak 1 | empty 0
// #981 (D164): with_concurrency starts the work itself and runs at most `n`
// of the tasks it starts at once, returning their results in input order
// (the later inputs here finish first). It documented a limit and ignored
// it; a Task-taking limiter cannot bound anything, because a Task is
// already running (§24.1).
use std.task
use std.time
use std.sync

let running: Atomic[i64] = Atomic.new(0)
let peak: Atomic[i64] = Atomic.new(0)

async fn square(i: i32) -> i32:
    let now = running.fetch_add(1) + 1
    if now > peak.load(): peak.store(now)
    sleep(Duration.millis(i)).await
    running.fetch_add(-1)
    i * i

fn main:
    let ids: List[i32] = [6, 5, 4, 3, 2, 1]
    let squares = ids |> with_concurrency(2, square)
    let two = peak.load()
    peak.store(0)
    let one = ids |> with_concurrency(1, square)
    let none: List[i32] = []
    let empty = none |> with_concurrency(3, square)
    print(f"{squares[0]} {squares[1]} {squares[2]} {squares[3]} {squares[4]} {squares[5]} | peak {two} | peak {peak.load()} | empty {empty.len()}")
    assert(one.len() == 6)
