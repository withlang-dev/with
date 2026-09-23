//! expect-check-fail: view `keep` may originate from `db`, which no longer lives here (§21.1 Rule 6)

// D51 stage 6 (ruling §29): a statement kept past its database's scope is
// refused where it is used.
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
    var keep: Option[Statement] = None
    if true:
        let db = Database.db_new(l, 1).unwrap()
        keep = Statement.st_new(db, 10)
    print(f"{keep.is_some()}")
