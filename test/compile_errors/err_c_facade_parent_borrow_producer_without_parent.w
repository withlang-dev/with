//! expect-check-fail: its producer 'kv_prepare_detached' states no 'borrows' parent of that type

// D85 (#2003; spec §16.2b.6): the parent is resolved through the
// argument resource's declared `borrows` clause. A `Statement` made by
// `kv_prepare_detached` declares no `Database` parent, so there is no
// parent to hand out on every `Statement`; the borrow is refused rather
// than read from a parent that may be absent.
use c_import("typedef struct kv_db kv_db;\ntypedef struct kv_stmt kv_stmt;\n#define KV_OK 0\nint kv_open(kv_db **out);\nvoid kv_close(kv_db *d);\nint kv_prepare(kv_db *d, kv_stmt **out);\nint kv_prepare_detached(kv_stmt **out);\nvoid kv_finalize(kv_stmt *s);\nint kv_step(kv_stmt *s);\nint kv_changes(kv_db *d);\nkv_db *kv_db_handle(kv_stmt *s);\nkv_db *kv_stmt_owner(kv_stmt *s);\n")

c facade kv:
    resource Database wraps *mut kv_db
        from kv_open(out param 0)
        drop kv_close
        ok KV_OK
    resource Statement wraps *mut kv_stmt
        from kv_prepare(out param 1)
        borrows param 0
        from kv_prepare_detached(out param 0)
        drop kv_finalize
        ok KV_OK
    fn kv_prepare
        rename prepare
    fn kv_step
        lend
    fn kv_changes
        lend
    fn kv_db_handle
        returns borrow Database from parent Database of param 0
        of Statement
        rename database

fn main:
    let db = Database.open().unwrap()
    let st = db.prepare().unwrap()
    print(st.step())
