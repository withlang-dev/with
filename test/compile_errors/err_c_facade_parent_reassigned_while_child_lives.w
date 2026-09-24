//! expect-check-fail: cannot mutate `db` while `s` is a live view into it

// D51 stage 6 (ruling §29): replacing the database a statement depends on
// while the statement is still used is refused.
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
    var db = Database.new(l, 1).unwrap()
    let s = Statement.new(db, 10).unwrap()
    db = Database.new(l, 2).unwrap()
    print(f"{s.step()}")
