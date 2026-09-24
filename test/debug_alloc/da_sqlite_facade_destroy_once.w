//! expect-debug-alloc: leak count=0
// D51 stage 12 (ruling §24, §66) under the debug allocator, against the
// real library: application data consumed by sqlite3_create_function_v2
// is boxed by the rendered method and destroyed by SQLite through xDestroy
// — once — when the function is replaced ("xDestroy will be invoked when
// the function is deleted, either by being overloaded or when the
// database connection closes") and when the connection closes, whether by
// its Drop at scope end, by an explicit close_v2, on an early return, or
// from a Vec of connections. Data destroyed twice is a DOUBLE FREE; data
// never destroyed is a LEAK. Statements are finalized before their
// connection on every path.
use facades.sqlite3
use c_import("sqlite3.h", link: "sqlite3")

type AppData { id: i32, name: str, seen: Vec[i32] }

fn silent(ctx: *mut sqlite3_context, n: c_int, argv: *mut *mut sqlite3_value): ()

fn register(db: &Database, id: i32) -> c_int:
    let x_func: extern "C" fn(*mut sqlite3_context, c_int, *mut *mut sqlite3_value) -> Unit = silent
    db.create_function_v2("silent", 0, SQLITE_UTF8, AppData { id: id, name: f"data {id}", seen: Vec.new() }, x_func, null, null)

fn early() -> i32:
    let db = Database.open(":memory:").unwrap()
    if register(db, 21) == SQLITE_OK:
        let stmt = db.prepare("SELECT silent()").unwrap()
        return stmt.step()
    0

fn main:
    if true:
        let db = Database.open(":memory:").unwrap()
        assert(register(db, 11) == SQLITE_OK)
        // Replaced: the first data is destroyed by the replacement.
        assert(register(db, 12) == SQLITE_OK)
        let stmt = db.prepare("SELECT silent()").unwrap()
        assert(stmt.step() == SQLITE_ROW)
    assert(early() == SQLITE_ROW)
    if true:
        let db = Database.open(":memory:").unwrap()
        assert(register(db, 31) == SQLITE_OK)
        assert(db.close_v2() == SQLITE_OK)
    if true:
        var all: Vec[Database] = Vec.new()
        for i in 1..4:
            let db = Database.open(":memory:").unwrap()
            assert(register(db, 40 + i) == SQLITE_OK)
            all.push(db)
        assert(all.len() == 3)
    match Database.open("/nonexistent-with-dir/x.db"):
        Err(DatabaseError.FailedWithResource(status, failed)) => assert(status == SQLITE_CANTOPEN)
        _ => assert(false)
