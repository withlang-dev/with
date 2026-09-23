//! expect-check-fail: implicit drop of `s` uses `&db` after `db` is moved (§21.1 Rule 7)

// D51 stage 6 (ruling §29): an alternate destroyer consumes the database,
// so calling it while a statement made from it lives is refused.
use c_import("../behavior/c_facade_children.h")

c facade dbf:
    resource Database wraps *mut db
        from db_new
        drop db_close
        destroys db_close_v2
    resource Statement wraps *mut st
        from db_prepare(out param out)
        from st_new
        drop st_finalize
    fn st_step
        lend
    fn db_close_v2
        destroys

fn main:
    let l = log_new()
    let db = Database.db_new(l, 1).unwrap()
    let (_, s) = Statement.db_prepare(db, 10)
    let rc = db.db_close_v2(0)
    print(f"{s.is_some()} {rc}")
