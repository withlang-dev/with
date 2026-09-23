//! expect-check-fail: = note: dependency: 'Link' depends on 'Database', which producer 'link_new' receives as param 0: *mut db a — stated by 'borrows param 0' in facade dbf (§16.2b.6)

// D51 stage 6 (ruling §8): a dependency the facade states is reported with
// the clause that states it.
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
    let a = Database.db_new(l, 1).unwrap()
    let b = Database.db_new(l, 2).unwrap()
    let link = Link.link_new(a, b, 3).unwrap()
    drop(a)
    print("end")
