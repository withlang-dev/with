//! expect-check-fail: ephemeral

// D51 stage 6 (ruling §26, §29): a borrowed database is ephemeral and cannot
// be stored in an ordinary struct.
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

type Keep { h: BorrowedDatabase }

fn main:
    print("x")
