//! expect-check-fail: view `keep` may originate from `db`, which no longer lives here (§21.1 Rule 6)

// D51 stage 12 (ruling §29, §54): a statement produced through the
// parent's presented method (`db.prepare(…)`, stage 8) depends on the
// database exactly as one produced through the constructor
// (`Statement.prepare(db, …)`, err_c_facade_child_outlives_parent_scope)
// — presentation changes spellings only. The receiver method is rendered
// inside `impl Database:`, and its signature was not found when the
// dependency summary was applied, so a statement kept past its database
// through this spelling was silently accepted.
use c_import("../behavior/c_facade_children.h")

c facade dbf:
    resource Database wraps *mut db
        from db_new
        drop db_close
    resource Statement wraps *mut st
        from db_prepare(out param out)
        drop st_finalize

fn main:
    let l = log_new()
    var keep: Option[Statement] = None
    if true:
        let db = Database.new(l, 1).unwrap()
        let (_, s) = db.prepare(10)
        keep = s
    print(f"{keep.is_some()}")
