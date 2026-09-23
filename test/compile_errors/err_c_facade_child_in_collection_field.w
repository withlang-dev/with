//! expect-check-fail: 'Holder' stores a 'Statement', which depends on its 'Database' and cannot be stored in a non-ephemeral type (§16.2b.6)

// D51 stage 6 (ruling §29: "cannot be stored where origin relationships
// cannot be preserved"): a collection of statements is ephemeral too.
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

type Holder { stmts: Vec[Statement], n: i32 }

fn main:
    print("x")
