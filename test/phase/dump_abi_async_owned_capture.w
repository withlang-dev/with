//! args: --dump-abi --no-prelude
//! expect-check-stdout: fn await_i32
//! expect-check-stdout: fn await_one
//! expect-check-stdout: -> OWNED
//! expect-check-stdout-not: SHARE-PLACE

// std.task declares Task a resource (D120); this prelude-free model does too.
resource type Task[T] { fiber_id: i32, result_buf: *mut u8 }

async fn echo[T](value: T) -> T: value

async fn await_i32(task: Task[i32]) -> i32: task.await

async fn await_one[T](task: Task[T]) -> T: task.await

async fn main:
    await_i32(echo(11)).await
    await_one(echo(17)).await
