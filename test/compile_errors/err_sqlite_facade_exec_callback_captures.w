//! expect-check-fail: capturing closure cannot coerce to extern "C" fn pointer

// D51 stage 12 (ruling §44, §66: "a callback API with userdata"; spec
// §12.4, §16.2b.9): sqlite3_exec's callback is a code pointer C receives
// alone — a closure with captures is refused; its state is the typed
// userdata the callback receives as `&U`.
use facades.sqlite3
use c_import("sqlite3.h", link: "sqlite3")

type Ctx { rows: i32 }

fn main:
    let db = Database.open(":memory:").unwrap()
    let seen = 0
    let ctx = Ctx { rows: 0 }
    let rc = db.exec("SELECT 1", Some((c, n, values, names) => seen + n), Some(&ctx))
    print(f"{rc}")
