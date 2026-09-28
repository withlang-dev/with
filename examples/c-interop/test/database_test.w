use facades.sqlite3
use c_import("sqlite3.h", link: "sqlite3")

fn seeded -> Database:
    let db = Database.open(":memory:").unwrap()
    assert(db.exec("CREATE TABLE t (name TEXT, n INTEGER); INSERT INTO t VALUES ('a', 1), (NULL, 2), ('c', 3)", None, None) == SQLITE_OK)
    db

fn message(db: &Database) -> str: db.errmsg().map(m => m.to_str_lossy()) ?? ""

type Scale { by: i32 }
fn scaled(ctx: Context, args: &[Value], scale: &Scale):
    var sum = 0
    for i in 0..args.len() as i32: sum = sum + args[i].int()
    ctx.result_int(sum * scale.by)

@[test]
fn exec_reports_rows_changed:
    let db = seeded()
    assert(db.exec("UPDATE t SET n = n + 1 WHERE n > 1", None, None) == SQLITE_OK)
    assert(db.changes() == 2)

@[test]
fn rows_come_back_in_order:
    let db = seeded()
    let rows = db.prepare("SELECT n FROM t ORDER BY n DESC").unwrap()
    var seen = ""
    while rows.step() == SQLITE_ROW: seen = seen ++ f"{rows.column_int(0)} "
    assert(seen == "3 2 1 ")

@[test]
fn a_null_column_is_none:
    let db = seeded()
    let rows = db.prepare("SELECT name FROM t ORDER BY n").unwrap()
    assert(rows.step() == SQLITE_ROW and rows.column_text(0).map(t => t.to_str_lossy()) == Some("a"))
    assert(rows.step() == SQLITE_ROW and rows.column_text(0).is_none())

@[test]
fn a_bound_parameter_narrows_the_query:
    let db = seeded()
    let above = db.prepare("SELECT n FROM t WHERE n > ? ORDER BY n").unwrap()
    assert(above.bind_int(1, 1) == SQLITE_OK)
    assert(above.step() == SQLITE_ROW and above.column_int(0) == 2)
    assert(above.step() == SQLITE_ROW and above.column_int(0) == 3)
    assert(above.step() == SQLITE_DONE)

@[test]
fn a_c_error_becomes_with_values:
    let db = seeded()
    assert(db.exec("SELECT * FROM nowhere", None, None) != SQLITE_OK)
    assert(db.errcode() == SQLITE_ERROR and message(&db).contains("nowhere"))

@[test]
fn a_failed_open_still_has_its_message:
    // The handle SQLite produced for a failed open is owned by the error
    // (`FailedWithResource`) and closed when the error is dropped; the one
    // operation valid on it is reading why it failed.
    match Database.open("/no/such/directory/db.sqlite"):
        Err(DatabaseError.FailedWithResource(status, failed)) =>
            assert(status == SQLITE_CANTOPEN)
            assert(failed.errmsg().map(m => m.to_str_lossy()) == Some("unable to open database file"))
        _ => assert(false)

@[test]
fn a_with_function_reads_its_sql_arguments_and_its_data:
    // An SQL function in With: SQLite hands it its arguments as `&[Value]`
    // and the application data the registration boxed as `&Scale`, valid for
    // the call; the body needs no `unsafe`.
    let db = seeded()
    assert(db.create_function_v2("scaled", -1, SQLITE_UTF8, Scale { by: 10 }, scaled, null, null) == SQLITE_OK)
    let rows = db.prepare("SELECT scaled(n, 2), scaled() FROM t WHERE n = 3").unwrap()
    assert(rows.step() == SQLITE_ROW and rows.column_int(0) == 50 and rows.column_int(1) == 0)
