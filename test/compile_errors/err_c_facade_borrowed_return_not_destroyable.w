//! expect-check-fail: unknown method 'db_close_v2' for type 'BorrowedDatabase'

// D51 stage 6 (ruling §26: a borrowed return "cannot independently be
// consumed or destroyed"): the database's destroyers are not presented on
// its borrowed value.
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
    let s = Statement.st_new(db, 10).unwrap()
    let handle = s.st_db().unwrap()
    let _ = handle.db_close_v2(0)
    print("x")
