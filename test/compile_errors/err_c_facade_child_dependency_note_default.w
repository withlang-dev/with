//! expect-check-fail: = note: dependency: 'Statement' depends on 'Database', which producer 'st_new' receives as param 0: *mut db d — conservative default of facade dbf: unknown independence means dependency (§16.2b.6)

// D51 stage 6 (ruling §8, §57): a dependency error on a facade's child names
// what it depends on, the producer and the resolved C parameter, and that
// the dependency is the conservative default.
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
    let s = Statement.new(db, 10).unwrap()
    drop(db)
    print(f"{s.step()}")
