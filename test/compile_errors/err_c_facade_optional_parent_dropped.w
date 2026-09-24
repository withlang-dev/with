//! expect-check-fail: implicit drop of `opened` uses `&db` after `db` is moved (§21.1 Rule 7)

// D51 stage 6: a cursor's producers differ — one receives a database, one
// does not — and the one made over a database still depends on it.
use c_import("../behavior/c_facade_children.h")

c facade dbf:
    resource Database wraps *mut db
        from db_new
        drop db_close
    resource Statement wraps *mut st
        from db_prepare(out param out)
        from st_new
        drop st_finalize
    resource Link wraps *mut lk
        from link_new
        drop link_free
        borrows param 0
    resource Backup wraps *mut bk
        from backup_init
        drop backup_finish
    resource Cursor wraps *mut cur
        from cur_open
        from cur_blank
        drop cur_close
    resource Iter wraps iter_state
        init it_init(self)
        drop it_end
    fn st_step
        lend

fn main:
    let l = log_new()
    let db = Database.new(l, 1).unwrap()
    let opened = Cursor.open(db, 2)
    drop(db)
    print("end")
