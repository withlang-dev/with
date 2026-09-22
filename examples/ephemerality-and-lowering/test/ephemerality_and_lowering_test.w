// Tests for ephemerality + with-lowering interactions

use std.sync

error AppError = DbError(str) | ProcessError | Cancelled

type DbConnection { id: i32 }
type ConnectionPool { url: str }

// The async test below makes the program concurrent, so the globals the
// defer probes write are Atomic (§9.1c): synchronized globals are always safe.
var defer_order_len: Atomic[i32] = Atomic.new(0)
var defer_order_third: Atomic[i32] = Atomic.new(0)
var defer_order_fourth: Atomic[i32] = Atomic.new(0)

fn with_connection(pool: ConnectionPool) -> DbConnection:
    print(f"Acquiring connection to {pool.url}...")
    defer: print("Releasing connection...")
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
    defer: defer_order_len.store(order.len(), .SeqCst)
    defer: defer_order_third.store(order[2], .SeqCst)
    defer: defer_order_fourth.store(order[3], .SeqCst)
    defer: order.push(4)
    defer: order.push(3)
    order.push(2)

@[test]
fn test_defer_order:
    defer_order_len.store(0, .SeqCst)
    defer_order_third.store(0, .SeqCst)
    defer_order_fourth.store(0, .SeqCst)
    run_defer_order()
    assert(defer_order_len.load(.SeqCst) == 4)
    assert(defer_order_third.load(.SeqCst) == 3)
    assert(defer_order_fourth.load(.SeqCst) == 4)

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

// A task is observed, never discarded (§14.7): the test is itself async and
// awaits the tracked tasks through the scope.
@[test]
async fn test_async_scope:
    let total = async scope s =>
        let a = s.track(process_item(1))
        let b = s.track(process_item(2))
        let c = s.track(process_item(3))
        a.await + b.await + c.await
    assert(total == 60)
