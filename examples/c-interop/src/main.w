use database
use tally

fn scores -> Result[Unit, DbError]:
    let db = Database.open(":memory:")?
    db.execute("CREATE TABLE users (name TEXT, email TEXT, score INTEGER)")?

    let insert = db.prepare("INSERT INTO users VALUES (?, ?, ?)")?
    for (name, score) in [("Alice", 95), ("Bob", 82), ("Charlie", 91)]:
        insert.bind_text(1, name)?
        insert.bind_int(3, score)?
        insert.step()?
        insert.reset()?

    let ranked = db.prepare("SELECT name, email, score FROM users ORDER BY score DESC")?
    while ranked.step()?:
        let name = ranked.text(0) ?? "?"
        let email = ranked.text(1) ?? "no email"
        print(f"{name} ({email}): {ranked.int(2)}")

    // What C reported, as a With value.
    match db.execute("SELECT * FROM nowhere"):
        Err(.Failed(code, message)) => print(f"sqlite said {code}: {message}")
        Ok(_) => print("unexpected success")

fn main -> Result[Unit, DbError]:
    print("-- a system library: sqlite3")
    scores()?

    print(f"-- a vendored library: tally {version()}")
    let readings = [4, -2, 7, 1]
    let range = range_of(readings)
    let wide = widened(range, 10)
    print(f"range {range.low}..{range.high}, widened {wide.low}..{wide.high}")
    print(f"C visited {visited(readings).len()} values through a With callback")
    print(f"C summed With's scores: {total(readings)}")
    print(f"tally was called {calls()} times")
