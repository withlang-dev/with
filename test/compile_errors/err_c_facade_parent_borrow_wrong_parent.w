//! expect-check-fail: 'Statement' declares no parent of type 'Cache'

// D85 (#2003; spec §16.2b.6): naming a parent the resource does not
// declare is an error. `Statement` borrows a `Database`; `from parent
// Cache` names a parent it does not have.
use c_import("typedef struct kv_db kv_db;\ntypedef struct kv_stmt kv_stmt;\ntypedef struct kv_cache kv_cache;\n#define KV_OK 0\nint kv_open(kv_db **out);\nvoid kv_close(kv_db *d);\nint kv_cache_open(kv_cache **out);\nvoid kv_cache_close(kv_cache *c);\nint kv_prepare(kv_db *d, kv_stmt **out);\nvoid kv_finalize(kv_stmt *s);\nint kv_step(kv_stmt *s);\nint kv_changes(kv_db *d);\nconst char *kv_errmsg(kv_db *d);\nconst unsigned char *kv_column_text(kv_stmt *s, int col);\nkv_db *kv_db_handle(kv_stmt *s);\nkv_cache *kv_stmt_cache(kv_stmt *s);\n")

c facade kv:
    resource Database wraps *mut kv_db
        from kv_open(out param 0)
        drop kv_close
        ok KV_OK
    resource Cache wraps *mut kv_cache
        from kv_cache_open(out param 0)
        drop kv_cache_close
        ok KV_OK
    resource Statement wraps *mut kv_stmt
        from kv_prepare(out param 1)
        drop kv_finalize
        ok KV_OK
        borrows param 0
    fn kv_prepare
        rename prepare
    fn kv_step
        lend
    fn kv_changes
        lend
    fn kv_errmsg
        returns borrow CStr from param 0
    fn kv_column_text
        returns borrow CStr from param 0
    fn kv_stmt_cache
        returns borrow Cache from parent Cache of param 0
        of Statement
        rename cache

fn main:
    let db = Database.open().unwrap()
    let st = db.prepare().unwrap()
    print(st.step())
