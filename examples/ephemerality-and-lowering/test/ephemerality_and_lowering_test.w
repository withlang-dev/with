// Tests for ephemerality + with-lowering interactions

error AppError = DbError(str) | ProcessError | Cancelled

type DbConnection { id: i32 }
type ConnectionPool { url: str }

var defer_order_len: i64 = 0
var defer_order_third: i32 = 0
var defer_order_fourth: i32 = 0

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

fn run_defer_order:
    var order = Vec.new()
    order.push(1)
    defer defer_order_len = order.len()
    defer defer_order_third = order.get(2)
    defer defer_order_fourth = order.get(3)
    defer order.push(4)
    defer order.push(3)
    order.push(2)

@[test]
fn test_defer_order:
    defer_order_len = 0
    defer_order_third = 0
    defer_order_fourth = 0
    run_defer_order()
    assert(defer_order_len == 4)
    assert(defer_order_third == 3)
    assert(defer_order_fourth == 4)

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
