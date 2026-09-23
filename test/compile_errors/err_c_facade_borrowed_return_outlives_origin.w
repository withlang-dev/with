//! expect-check-fail: view `handle` may originate from `s`, which no longer lives here (§21.1 Rule 6)

// D51 stage 6 (ruling §26: a borrowed return "cannot outlive the named
// origin"): the borrowed database cannot be used past the statement it
// came from, and the diagnostic says where it was borrowed from (§57).
use c_import("../behavior/c_facade_children.h")

c facade dbf:
    resource Database wraps *mut db
        from db_new
        drop db_close
        destroys db_close_v2
    resource Statement wraps *mut st
        from st_new
        drop st_finalize
    fn db_close_v2
        destroys
    fn st_db
        returns borrow Database from param 0

fn main:
    let l = log_new()
    let db = Database.db_new(l, 1).unwrap()
    var handle: Option[BorrowedDatabase] = None
    if true:
        let s = Statement.st_new(db, 10).unwrap()
        handle = s.st_db()
    print(f"{handle.is_some()}")
