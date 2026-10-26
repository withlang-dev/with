//! expect-stdout: 30 | 60
// §24.1: `async fn quick(i: i32) -> i32` is `fn quick(i: i32) -> Task[i32]`;
// its value spawns as a direct call does. Called through a parameter or
// mapped over a list, the value ran the body and returned its i32 where a
// Task was expected, and the await read through it (segfault).
use std.task

async fn quick(i: i32) -> i32: i * 10

fn apply(f: fn(i32) -> Task[i32], x: i32) -> Task[i32]: f(x)

fn main:
    let one = apply(quick, 3).await
    var total = 0
    for t in [3, 2, 1] |> map(quick):
        total += t.await
    print(f"{one} | {total}")
