//! expect-check-fail: view `keep` may originate from `db`, which no longer lives here (§21.1 Rule 6)

// D51 stage 12 (ruling §27, §29, §66: "sqlite3_stmt as a dependent child
// resource"): a prepared statement depends on the connection it was
// prepared on (`borrows param 0`), so one kept past the connection's
// scope — where sqlite3_finalize would touch a closed connection — is
// refused where it is used.
use facades.sqlite3
use c_import("sqlite3.h", link: "sqlite3")

fn main:
    var keep: Option[Statement] = None
    if true:
        let db = Database.open(":memory:").unwrap()
        keep = db.prepare("SELECT 1").ok()
    print(f"{keep.is_some()}")
