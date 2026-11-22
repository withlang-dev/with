//! expect-check-fail: cannot mutate `db` while `s` is a live view into it
//! expect-check-fail: = help: if the C API guarantees 'Statement' does not depend on the resources its producers receive, state 'independent' on resource 'Statement' in facade dbf; if it depends on only some of them, name those with 'borrows param N'

// D51 stage 6 (ruling §29): replacing the database a statement depends on
// while the statement is still used is refused.
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
    var db = Database.new(l, 1).unwrap()
    let s = Statement.new(db, 10).unwrap()
    db = Database.new(l, 2).unwrap()
    print(f"{s.step()}")
