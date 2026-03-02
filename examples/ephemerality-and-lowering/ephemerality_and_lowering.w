module tests.ephemerality_and_lowering

use std.time.Duration
use std.sync.Mutex

error AppError = DbError(str) | ProcessError | Cancelled

// ============================================================================
// 1. SETUP: Custom `Scoped` implementation to test `with` lowering
// ============================================================================

type DbConnection = { id: i32 }
type ConnectionPool = { url: str }

// To support `with pool as conn:`, a type implements `Scoped[T]`.
// The `enter` function uses `defer` to guarantee cleanup.
impl Scoped[DbConnection] for ConnectionPool:
    fn enter[R](self: &ConnectionPool, f: fn(&DbConnection) -> R) -> R:
        println("Acquiring connection to {self.url}...")
        defer println("Releasing connection...")

        let conn = DbConnection { id: 42 }
        f(&conn)

// ============================================================================
// 2. SETUP: Ephemeral traits and generics
// ============================================================================

trait Processor:
    fn process(self: &Self, data: &str) -> str

// An ephemeral struct capturing a borrowed view.
type BorrowingProcessor = ephemeral { prefix: StrView }

impl Processor for BorrowingProcessor:
    fn process(self: &BorrowingProcessor, data: &str) -> str:
        "{self.prefix}: {data}"

// ============================================================================
// TEST SUITE
// ============================================================================

fn test_ephemeral_boundaries:
    let local_str = "TRACE".to_owned()

    // 1. Ephemeral struct creation
    let proc = BorrowingProcessor { prefix: local_str.as_view() }

    // 2. Trait Object Boundary
    // `dyn_proc` is ephemeral because it references `proc`.
    let dyn_proc: &dyn Processor = &proc

    // 3. Generic Functions + Nested Calls
    // The literal array borrows static strings, creating an ephemeral slice.
    let items: &[&str] = &["login", "logout"]
    let results = apply_processor(dyn_proc, items)

    assert_eq(results[0], "TRACE: login")

// Generic function taking a trait object and an ephemeral container.
// Rule 3: `Vec[&str]` inherits ephemerality from `&str`. It cannot escape.
fn apply_processor(p: &dyn Processor, items: &[&str]) -> Vec[String]:
    // 4. Closures capturing ephemeral references
    // This closure is non-escaping (passed directly to map). It is allowed
    // to capture `p` (ephemeral) and `s` (ephemeral).
    items.iter()
        |> map(|s| p.process(s))
        |> collect[Vec]()

    // IF WE WROTE THIS, IT WOULD BE A COMPILE ERROR (Rule 9):
    // let bad_closure = |s| p.process(s)
    // return bad_closure // ERROR: escaping closure captures ephemeral value `p`

async fn test_async_ephemeral_interaction -> Result[Unit, AppError]:
    var shared_buffer = vec![1, 2, 3]

    // 5. Async + Ephemeral Interaction
    // `process_buffer` takes `&mut Vec`. It returns a Task that captures it.
    // The compiler marks `task` as EPHEMERAL. It cannot be returned or stored.

    async scope |s|:
        // s.track() accepts the ephemeral task. The scope guarantees
        // the task will join/cancel before `shared_buffer` goes out of scope.
        let task = s.track(process_buffer(&mut shared_buffer))

        // Let's also test `with` lowering inside async!
        let pool = ConnectionPool { url: "localhost" }

        // 6. Nested with blocks & ? propagation & early return
        with pool as conn1, pool as conn2:
            if conn1.id != conn2.id:
                // Non-local control flow! This returns from `test_async_ephemeral`.
                // The compiler safely unwinds the `enter` closures, triggering
                // the `defer println("Releasing...")` calls automatically.
                return Err(.ProcessError)

            // Suspension point! The fiber yields.
            // The `with` guard (ConnectionPool) is NOT @[no_await_guard], so this is safe.
            sleep(Duration.millis(5)).await

            // Wait for the ephemeral task
            task.await?

    // Safe to read `shared_buffer` again; the async scope proved it joined.
    assert_eq(shared_buffer.len(), 4)

// Async function borrowing data (fiber has a real stack).
async fn process_buffer(data: &mut Vec[i32]) -> Result[Unit, AppError]:
    // Async suspension point.
    // The reference `data` survives across `.await` flawlessly because
    // With uses fibers, not struct-based state machines.
    sleep(Duration.millis(10)).await

    data.push(42)
    // implicit Ok(())
