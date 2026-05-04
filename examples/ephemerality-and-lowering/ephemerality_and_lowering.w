// ===================================================================
// Ephemerality and Lowering — Demonstrates with-blocks,
// defer, async scope, and structured resource management.
// ===================================================================

error AppError = DbError(str) | ProcessError | Cancelled

// --- Resource management with defer ---

type DbConnection { id: i32 }
type ConnectionPool { url: str }

fn with_connection(pool: ConnectionPool) -> DbConnection:
    print(f"Acquiring connection to {pool.url}...")
    defer: print("Releasing connection...")
    DbConnection { id: 42 }

// --- Scoped mutation with `with` ---

fn test_with_blocks:
    let pool = ConnectionPool { url: "localhost:5432" }
    let conn = with_connection(pool)
    print(f"Got connection #{conn.id}")

    // with-as for scoped naming
    with "hello world" as greeting:
        print(greeting)

    // Nested with blocks
    with 10 as x:
        with 20 as y:
            let sum = x + y
            assert(sum == 30)

// --- Async scope for structured concurrency ---

async fn process_item(id: i32) -> i32:
    id * 10

async fn test_async_scope:
    var result = 0

    async scope s =>
        s.track(process_item(1))
        s.track(process_item(2))
        s.track(process_item(3))

    print("all async tasks completed")

// --- Defer for cleanup ---

fn test_defer:
    print("start")
    defer: print("cleanup 1")
    defer: print("cleanup 2")
    print("middle")
    // defers run in reverse order: cleanup 2,: cleanup 1

// --- Vec mutation ---

fn test_vec_mutation:
    var buffer = Vec.new()
    buffer.push(1)
    buffer.push(2)
    buffer.push(3)
    assert(buffer.len() == 3)

    buffer.push(42)
    assert(buffer.len() == 4)

fn main:
    test_with_blocks()
    test_defer()
    test_vec_mutation()
    let _ = test_async_scope()
    print("=== all tests passed ===")
