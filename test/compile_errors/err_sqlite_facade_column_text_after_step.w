//! expect-check-fail: view `text` borrows from `stmt`, which `sqlite3_step` may have invalidated (§16.2b.7)

// D51 stage 12 (ruling §38, §66: "view invalidation across statement
// mutation"): sqlite3.h — "The pointers returned are valid until a type
// conversion occurs as described above, or until sqlite3_step() or
// sqlite3_reset() or sqlite3_finalize() is called" — so the facade states
// no preservation on step, and a column text view read after the next
// step is refused where it is used. column_bytes, which preserves, is fine
// in between (behav_sqlite_facade_end_to_end).
use facades.sqlite3
use c_import("sqlite3.h", link: "sqlite3")

fn main:
    let db = Database.open(":memory:").unwrap()
    let stmt = db.prepare("SELECT 'a' UNION ALL SELECT 'b'").unwrap()
    assert(stmt.step() == SQLITE_ROW)
    let text = stmt.column_text(0).unwrap()
    let _ = stmt.column_bytes(0)
    assert(stmt.step() == SQLITE_ROW)
    print(f"{text.to_str().unwrap()}")
