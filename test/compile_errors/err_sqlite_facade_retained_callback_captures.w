//! expect-check-fail: wrong argument type in call to 'Database.create_function_v2'
//! expect-check-fail: expects extern "C" fn(*mut sqlite3_context, i32, *mut *mut sqlite3_value) -> Unit

// D51 stage 12 (ruling §45, §66: "retained callback/userdata lifetime";
// spec §12.4, §16.2b.9): the function pointers sqlite3_create_function_v2
// retains are code pointers C receives alone, so a closure with captures
// is refused — its state belongs in the application data the connection
// owns and hands back through sqlite3_user_data. (The refusal is the
// argument-type mismatch today; with #1609 the generic method's parameter
// types the closure and the message becomes "capturing closure cannot
// coerce to extern "C" fn pointer", as for `db.exec`.)
use facades.sqlite3
use c_import("sqlite3.h", link: "sqlite3")

fn main:
    let db = Database.open(":memory:").unwrap()
    let calls = 0
    let rc = db.create_function_v2("count", 0, SQLITE_UTF8, 1, (ctx, n, argv) => { let _ = calls }, null, null)
    print(f"{rc}")
