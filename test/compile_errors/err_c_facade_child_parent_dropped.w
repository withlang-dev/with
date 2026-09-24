//! expect-check-fail: `db` is moved here while `s` still borrows it

// D51 stage 6 (ruling §29): dropping the database while a statement made
// from it lives is refused at the drop.
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
    let db = Database.new(l, 1).unwrap()
    let s = Statement.new(db, 10).unwrap()
    drop(db)
    print(f"{s.step()}")
