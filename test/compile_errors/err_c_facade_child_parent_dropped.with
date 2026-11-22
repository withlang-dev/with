//! expect-check-fail: `db` is moved here while `s` still borrows it
//! expect-check-fail: = help: drop or finish with `s` before `db` is moved or consumed

// D51 stage 6 (ruling §29): dropping the database while a statement made
// from it lives is refused at the drop.
use c_import("../behavior/c_facade_children.h")

c contract dbf:
    resource Database wraps *mut db
        from db_new
        drop db_close
        destroys db_close_v2
    resource Statement wraps *mut st
        from db_prepare(out param out)
        from st_new
        drop st_finalize
    fn db_prepare
        of Statement
    fn st_new
        of Statement
    fn st_step
        lend

fn main:
    let l = log_new()
    let db = Database.new(l, 1).unwrap()
    let s = Statement.new(db, 10).unwrap()
    drop(db)
    print(f"{s.step()}")
