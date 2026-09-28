//! skip-on: windows no host sqlite3 on Windows: this c_imports the host library's header (Linux CI installs it); the release UAT project gets it from `with get`
//! expect-check-fail: 'Value' is a callback-scope handle, borrowed for the callback's invocation, and cannot outlive it

// Spec §16.2b.9 (D76, ruling Amendment 2, #1779): the arguments of an SQL
// function are "valid for the callback's invocation only" — SQLite makes
// each `sqlite3_value` for the call. Kept in global storage for use after
// the function returns, the slice would point into an invocation SQLite has
// finished; it is ephemeral, and the storage that would outlive the
// callback is refused.
use facades.sqlite3
use c_import("sqlite3.h", link: "sqlite3")

var LAST_ARGS: Option[&[Value]] = None

fn remember(ctx: Context, args: &[Value], app: &i32):
    LAST_ARGS = Some(args)

fn main:
    let db = Database.open(":memory:").unwrap()
    print(f"{db.create_function_v2("remember", 1, SQLITE_UTF8, 0, remember, null, null)}")
