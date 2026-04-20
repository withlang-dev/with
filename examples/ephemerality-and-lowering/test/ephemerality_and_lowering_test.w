// Tests for ephemerality + with-lowering interactions

error AppError = DbError(str) | ProcessError | Cancelled

type DbConnection { id: i32 }
type ConnectionPool { url: str }

fn with_connection(pool: ConnectionPool) -> DbConnection:
    print(f"Acquiring connection to {pool.url}...")
    defer print("Releasing connection...")
    DbConnection { id: 42 }

@[test]
fn test_with_blocks:
    let pool = ConnectionPool { url: "localhost:5432" }
    let conn = with_connection(pool)
    assert(conn.id == 42)

    with 10 as x:
        with 20 as y:
            assert(x + y == 30)

@[test]
fn test_defer_order:
    var order = Vec.new()
    order.push(1)
    defer order.push(4)
    defer order.push(3)
    order.push(2)
    assert(order.len() == 4)

@[test]
fn test_vec_mutation:
    var buffer = Vec.new()
    buffer.push(1)
    buffer.push(2)
    buffer.push(3)
    assert(buffer.len() == 3)

    buffer.push(42)
    assert(buffer.len() == 4)

async fn process_item(id: i32) -> i32:
    id * 10

@[test]
fn test_async_scope:
    let _ = async:
        async scope s =>
            s.track(process_item(1))
            s.track(process_item(2))
            s.track(process_item(3))
