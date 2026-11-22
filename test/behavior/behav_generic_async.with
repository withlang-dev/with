//! expect-stdout: ok

use std.task.Task
type Pair[T] { first: T, second: T }

async fn echo[T](value: T) -> T: value

async fn await_one[T](task: Task[T]) -> T: task.await

async fn Pair.total(self: &Self) -> T: self.first + self.second

async fn main:
    assert(echo(42).await == 42)
    assert(echo("hello").await == "hello")

    let echoed = echo(Pair { first: 10, second: 20 }).await
    assert(echoed.first == 10)
    assert(echoed.second == 20)

    assert(await_one(echo(17)).await == 17)

    let pair = Pair { first: 7, second: 8 }
    assert(pair.total().await == 15)
    print("ok")
