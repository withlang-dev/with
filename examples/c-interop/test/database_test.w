use database

fn seeded -> Result[Database, DbError]:
    let db = Database.open(":memory:")?
    db.execute("CREATE TABLE t (name TEXT, n INTEGER)")?
    db.execute("INSERT INTO t VALUES ('a', 1), (NULL, 2), ('c', 3)")?
    db

@[test]
fn execute_reports_rows_changed:
    let db = seeded().unwrap()
    assert(db.execute("UPDATE t SET n = n + 1 WHERE n > 1").unwrap() == 2)

@[test]
fn rows_come_back_in_order:
    let db = seeded().unwrap()
    let rows = db.prepare("SELECT n FROM t ORDER BY n DESC").unwrap()
    var seen = ""
    while rows.step().unwrap(): seen = seen ++ f"{rows.int(0)} "
    assert(seen == "3 2 1 ")

@[test]
fn a_null_column_is_none:
    let db = seeded().unwrap()
    let rows = db.prepare("SELECT name FROM t ORDER BY n").unwrap()
    assert(rows.step().unwrap() and rows.text(0) == Some("a"))
    assert(rows.step().unwrap() and rows.text(0) == None)

@[test]
fn bound_text_survives_the_call:
    let db = seeded().unwrap()
    let find = db.prepare("SELECT n FROM t WHERE name = ?").unwrap()
    find.bind_text(1, "abc".slice(2, 3)).unwrap()  // a runtime str, not a literal
    assert(find.step().unwrap() and find.int(0) == 3)

@[test]
fn a_c_error_becomes_a_with_error:
    let db = seeded().unwrap()
    match db.execute("SELECT * FROM nowhere"):
        Err(.Failed(code, message)) => assert(code == 1 and message.contains("nowhere"))
        Ok(_) => assert(false)

@[test]
fn a_failed_open_still_closes:
    assert(Database.open("/no/such/directory/db.sqlite").is_err())
