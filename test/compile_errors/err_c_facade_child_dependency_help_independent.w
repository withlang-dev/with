//! expect-check-fail: = help: if the C API guarantees 'Statement' does not depend on the resources its producers receive, state 'independent' on resource 'Statement' in facade dbf; if it depends on only some of them, name those with 'borrows param N'

// D51 stage 6 (ruling §8: "help: declare this producer independent if the
// C API guarantees independence"): a conservative dependency names the
// clause that would lift it.
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
    let db = Database.db_new(l, 1).unwrap()
    let s = Statement.st_new(db, 10).unwrap()
    let moved = db
    print(f"{s.st_step()}")
