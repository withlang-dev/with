//! skip-on: windows no host sqlite3 on Windows: this c_imports the host library's header (Linux CI installs it); the release UAT project gets it from `with get`
//! expect-check-fail: capturing closure cannot coerce to extern "C" fn pointer

// D51 stage 12 (ruling §45, §66: "retained callback/userdata lifetime";
// spec §12.4, §16.2b.9): the function pointers sqlite3_create_function_v2
// retains are code pointers C receives alone, so a closure with captures
// is refused — its state belongs in the application data the connection
// owns and hands back to the function as `&U` (D76). The generic method's
// parameter types the closure — `extern "C" fn(Context, &[Value], &U)`
// with `U` the application data's type — so the refusal is the capture
// itself, as for `db.exec`.
use facades.sqlite3
use c_import("sqlite3.h", link: "sqlite3")

fn main:
    let db = Database.open(":memory:").unwrap()
    let calls = 0
    let rc = db.create_function_v2("count", 0, SQLITE_UTF8, 1, (ctx, args, app) => { let _ = calls }, null, null)
    print(f"{rc}")
