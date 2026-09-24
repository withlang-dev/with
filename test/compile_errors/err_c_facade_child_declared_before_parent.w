//! expect-check-fail: implicit drop of `keep` uses `&db` after `db` is destroyed (§21.1 Rule 7)

// D51 stage 6 (ruling §29: "is destroyed before required origins"): an
// Option holding a statement, declared before its database, would drop
// after it — the Option's drop runs the statement's, so it is refused as
// the statement itself is.
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
    var keep: Option[Statement] = None
    let db = Database.new(l, 1).unwrap()
    keep = Statement.new(db, 10)
    print("end")
