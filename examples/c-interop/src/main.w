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

// Every SQLite call that can fail returns a `Result` whose error is the one
// the facade states for the library, `SqliteError`: the status SQLite
// returned and the message it keeps on the connection, copied before the
// next call replaces it. One error type, so `?` carries any of them out.

// An SQL function written in With. SQLite calls it with its context, its
// arguments and the application data registered with it; the facade
// presents them as a callback-scope `Context`, a slice of `Value` handles
// and a view of the registered `Bonus` — each valid for this call only —
// and the compiler generates the wrapper C actually invokes. The body reads
// them and sets its result with no `unsafe`.
type Bonus { points: i32 }
fn boosted(ctx: Context, args: &[Value], bonus: &Bonus):
    var sum = 0
    for i in 0..args.len() as i32: sum = sum + args[i].int()
    ctx.result_int(sum + bonus.points)

fn scores -> Result[Unit, SqliteError]:
    // An owned connection: closed when `db` leaves its scope, on every path.
    let db = Database.open(":memory:")?
    db.exec("CREATE TABLE users (name TEXT, email TEXT, score INTEGER); INSERT INTO users VALUES ('Alice', NULL, 95), ('Bob', NULL, 82), ('Charlie', NULL, 91)")?

    // A prepared statement depends on its connection: it is finalized before
    // the connection closes, and cannot be stored beside it. Parameters are
    // numbered from 1, as SQLite numbers them.
    let ranked = db.prepare("SELECT name, email, score FROM users WHERE score > ? ORDER BY score DESC")?
    ranked.bind_int(1, 80)?
    // The registration consumes the application data: SQLite owns it now,
    // and destroys it — through the callback the compiler supplies — when the
    // function is replaced or the connection closes.
    db.create_function_v2("boosted", 1, SQLITE_UTF8, Bonus { points: 5 }, boosted, None, None)?
    // A row and the end of the rows are both successes; anything else is the
    // error `?` returns.
    while ranked.step()? == SQLITE_ROW:
        // Columns are numbered from 0. A NULL column is `None`, not "".
        let score = ranked.column_int(2)
        let name = ranked.column_text(0).map(t => t.to_str_lossy()) ?? "?"
        let email = ranked.column_text(1).map(t => t.to_str_lossy()) ?? "no email"
        print(f"{name} ({email}): {score}")
    // The With function, called by SQL.
    let best = db.prepare("SELECT boosted(MAX(score)) FROM users")?
    if best.step()? == SQLITE_ROW: print(f"boosted best score: {best.column_int(0)}")

    // What C reported, as With values: the status, and the message.
    match db.exec("SELECT * FROM nowhere"):
        Err(.Failed(status, message)) => print(f"sqlite said {status}: {message}")
        Err(other) => print(f"sqlite failed: {other}")
        Ok(_) => print("sqlite accepted a table that does not exist")

fn main:
    print("-- a system library: sqlite3")
    match scores():
        Err(e) =>
            print(f"sqlite failed: {e}")
            return 1
        Ok(_) => {}

    print(f"-- a vendored library: tally {TALLY_VERSION}")
    let readings = [4, -2, 7, 1]
    let range = range_of(readings)
    let wide = widened(range, 10)
    print(f"range {range.low}..{range.high}, widened {wide.low}..{wide.high}")
    print(f"C visited {visited(readings).len()} values through a With callback")
    print(f"C summed With's scores: {total(readings)}")
    print(f"tally was called {calls()} times")
