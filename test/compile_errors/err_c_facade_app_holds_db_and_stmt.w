//! expect-check-fail: help: borrow the parent instead of owning it, so App lives no longer than it: `type App = ephemeral { db: &Database, stmt: Statement }`

// D51 stage 6 (ruling §30): a type holding a database and a statement that
// borrows from it is a self-referential layout; the fix that compiles is
// named.
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

type App { db: Database, stmt: Statement }

fn main:
    print("x")
