// Two C libraries from one program: the one the system provides (SQLite) and
// one vendored as source (vendor/tally.c). No `unsafe` here: the SQLite
// facade (src/facades/sqlite3.w) states what sqlite3.h cannot — which call
// produces a connection, which closes it, what a returned pointer borrows
// from — and the compiler renders the safe surface from it. The raw import
// names the status constants.
use facades.sqlite3
use c_import("sqlite3.h", link: "sqlite3")
use c_import("tally.h")
use tally

// SQLite keeps its message on the connection until the next call replaces it.
// The facade renders it as a view of the connection (`Option[&CStr]`); it is
// copied into With text here, explicitly, before anything invalidates it.
fn message(db: &Database) -> str: db.errmsg().map(m => m.to_str_lossy()) ?? "(no message)"

fn scores -> i32:
    // An owned connection: closed when `db` leaves its scope, on every path.
    let Ok(db) = Database.open(":memory:") else:
        print("could not open an in-memory database")
        return 1
    // No row callback: `None` declines it, and the userdata it would receive.
    if db.exec("CREATE TABLE users (name TEXT, email TEXT, score INTEGER); INSERT INTO users VALUES ('Alice', NULL, 95), ('Bob', NULL, 82), ('Charlie', NULL, 91)", None, None) != SQLITE_OK:
        print(f"seeding failed: {message(&db)}")
        return 1

    // A prepared statement depends on its connection: it is finalized before
    // the connection closes, and cannot be stored beside it. Parameters are
    // numbered from 1, as SQLite numbers them.
    let Ok(ranked) = db.prepare("SELECT name, email, score FROM users WHERE score > ? ORDER BY score DESC") else:
        print(f"prepare failed: {message(&db)}")
        return 1
    ranked.bind_int(1, 80)
    while ranked.step() == SQLITE_ROW:
        // Columns are numbered from 0. A NULL column is `None`, not "".
        let score = ranked.column_int(2)
        let name = ranked.column_text(0).map(t => t.to_str_lossy()) ?? "?"
        let email = ranked.column_text(1).map(t => t.to_str_lossy()) ?? "no email"
        print(f"{name} ({email}): {score}")

    // What C reported, as With values: the status, and the message.
    if db.exec("SELECT * FROM nowhere", None, None) != SQLITE_OK:
        print(f"sqlite said {db.errcode()}: {message(&db)}")
    0

fn main:
    print("-- a system library: sqlite3")
    if scores() != 0: return 1

    print(f"-- a vendored library: tally {TALLY_VERSION}")
    let readings = [4, -2, 7, 1]
    let range = range_of(readings)
    let wide = widened(range, 10)
    print(f"range {range.low}..{range.high}, widened {wide.low}..{wide.high}")
    print(f"C visited {visited(readings).len()} values through a With callback")
    print(f"C summed With's scores: {total(readings)}")
    print(f"tally was called {calls()} times")
