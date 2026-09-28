//! skip-on: windows no host sqlite3 on Windows: this c_imports the host library's header (Linux CI installs it); the release UAT project gets it from `with get`
//! expect-check-fail: 'Context' is a callback-scope handle, borrowed for the callback's invocation, and cannot outlive it

// Spec §16.2b.9 (D71, ruling Amendment 1, #1611): the `Context` SQLite
// passes an SQL function is "borrowed for the callback's scope and cannot
// outlive it". Kept in global storage for use after the call returns, it
// would be a pointer into an invocation SQLite has finished; the handle is
// ephemeral, and the storage that would outlive the callback is refused.
use facades.sqlite3
use c_import("sqlite3.h", link: "sqlite3")

var LAST: Option[Context] = None

fn remember(ctx: Context, args: &[Value], app: &i32):
    LAST = Some(ctx)

fn main:
    let db = Database.open(":memory:").unwrap()
    print(f"{db.create_function_v2("remember", 0, SQLITE_UTF8, 0, remember, null, null)}")
