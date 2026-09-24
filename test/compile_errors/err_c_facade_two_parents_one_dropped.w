//! expect-check-fail: implicit drop of `backup` uses `&src` after `src` is moved (§21.1 Rule 7)

// D51 stage 6 (ruling §27: "a resource may depend on multiple parents"; the
// child remains valid only while all remain valid): a backup made from two
// databases cannot outlive either.
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
    let src = Database.new(l, 1).unwrap()
    let dest = Database.new(l, 2).unwrap()
    let backup = Backup.backup_init(dest, src, 3)
    drop(src)
    print("end")
