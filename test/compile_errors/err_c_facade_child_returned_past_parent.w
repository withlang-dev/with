//! expect-check-fail: returned ephemeral value may outlive its origin 'db'

// D51 stage 6 (ruling §29: "cannot escape through an invalid return"): a
// statement cannot be returned past the database it depends on.
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

fn make(l: Log) -> Statement:
    let db = Database.new(l, 1).unwrap()
    Statement.new(db, 10).unwrap()

fn main:
    print(f"{make(log_new()).step()}")
