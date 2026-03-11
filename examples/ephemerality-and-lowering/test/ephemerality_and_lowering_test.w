// Tests for ephemerality + with-lowering interactions

use test.testing
use std.time.Duration

error AppError = DbError(str) | ProcessError | Cancelled

type DbConnection = { id: i32 }
type ConnectionPool = { url: str }

impl Scoped[DbConnection] for ConnectionPool:
    fn enter[R](self: &ConnectionPool, f: fn(&DbConnection) -> R) -> R:
        println("Acquiring connection to {self.url}...")
        defer println("Releasing connection...")

        let conn = DbConnection { id: 42 }
        f(&conn)

trait Processor:
    fn process(self: &Self, data: &str) -> str

type BorrowingProcessor = ephemeral { prefix: StrView }

impl Processor for BorrowingProcessor:
    fn process(self: &BorrowingProcessor, data: &str) -> str:
        "{self.prefix}: {data}"

fn apply_processor(p: &dyn Processor, items: &[&str]) -> Vec[String]:
    items.iter()
        |> map(s => p.process(s))
        |> collect[Vec]()

@[test]
fn test_ephemeral_boundaries:
    let local_str = "TRACE".to_owned()

    let proc = BorrowingProcessor { prefix: local_str.as_view() }
    let dyn_proc: &dyn Processor = &proc

    let items: &[&str] = &["login", "logout"]
    let results = apply_processor(dyn_proc, items)

    assert_true(results[0] == "TRACE: login")

@[test]
async fn test_async_ephemeral_interaction -> Result[Unit, AppError]:
    var shared_buffer = vec![1, 2, 3]

    async scope s =>
        let task = s.track(process_buffer(&mut shared_buffer))
        let pool = ConnectionPool { url: "localhost" }

        with pool as conn1, pool as conn2:
            if conn1.id != conn2.id:
                return Err(.ProcessError)

            sleep(Duration.millis(5)).await
            task.await?

    assert_true(shared_buffer.len() == 4)

async fn process_buffer(data: &mut Vec[i32]) -> Result[Unit, AppError]:
    sleep(Duration.millis(10)).await
    data.push(42)
