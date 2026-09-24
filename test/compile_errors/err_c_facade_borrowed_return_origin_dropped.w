//! expect-check-fail: = note: borrowed: 'BorrowedDatabase' is borrowed from the 'Statement' that 'st_db' receives as param 0: *mut st s — stated by 'returns borrow Database from param 0' in facade dbf; it has no Drop and cannot outlive that origin (§16.2b.6)

// D51 stage 6 (ruling §26, §57): dropping the statement while its borrowed
// database is still used is refused, naming the clause.
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
    let db = Database.new(l, 1).unwrap()
    let s = Statement.new(db, 10).unwrap()
    let handle = s.db().unwrap()
    drop(s)
    print(f"{handle.repr == null}")
