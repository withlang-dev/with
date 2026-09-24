//! expect-check-fail: implicit drop of `s` uses `&db` after `db` is moved (§21.1 Rule 7)

// D51 stage 6 (ruling §27, §29; spec §16.2b.6): a statement depends on the
// database it was prepared on, so moving the database while the statement
// lives is refused at the move.
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
    let moved = db
    print(f"{s.step()}")
