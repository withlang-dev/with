//! expect-stdout: changes 2
//! expect-stdout: row 2 changes 4
//! expect-stdout: handle changes 4
//! expect-stdout: ok

// D85 (#2003; spec §16.2b.6): `returns borrow Database from parent Database
// of param 0` hands out the statement's parent connection. The borrow lives
// as long as the parent's origin (`db`), not the statement's, so the
// statement's own operations do not invalidate it: `st.step()` then
// `b.changes()` is accepted (it was refused under `from param 0`, which
// makes the borrow a view of the statement: err_1977_borrowed_resource_after_step).
use c_import("#include <stdlib.h>
#define KV_OK 0
typedef struct kv_db { int changes; } kv_db;
typedef struct kv_stmt { kv_db *owner; int row; } kv_stmt;
static inline int kv_open(kv_db **out) { kv_db *d = (kv_db *)malloc(sizeof(kv_db)); d->changes = 0; *out = d; return KV_OK; }
static inline void kv_close(kv_db *d) { free(d); }
static inline int kv_prepare(kv_db *d, kv_stmt **out) { kv_stmt *s = (kv_stmt *)malloc(sizeof(kv_stmt)); s->owner = d; s->row = 0; *out = s; return KV_OK; }
static inline void kv_finalize(kv_stmt *s) { free(s); }
static inline int kv_step(kv_stmt *s) { s->row++; s->owner->changes++; return s->row; }
static inline int kv_changes(kv_db *d) { return d->changes; }
static inline kv_db *kv_db_handle(kv_stmt *s) { return s->owner; }
")

c facade kv:
    resource Database wraps *mut kv_db
        from kv_open(out param 0)
        drop kv_close
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
    fn kv_db_handle
        returns borrow Database from parent Database of param 0
        of Statement
        rename database

fn rows(db: &Database):
    let st = db.prepare().unwrap()
    let b = st.database().unwrap()
    st.step()
    let row = st.step()
    // `b` is the connection, not the statement: `st`'s steps leave it valid.
    print(f"row {row} changes {b.changes()}")

// The borrow outlives the statement it came from: its origin is the
// connection `db` names, so it may leave the function `st` dies in.
fn handle_of(db: &Database) -> BorrowedDatabase:
    let st = db.prepare().unwrap()
    st.database().unwrap()

fn main:
    let db = Database.open().unwrap()
    let st = db.prepare().unwrap()
    let b = st.database().unwrap()
    st.step()
    st.step()
    print(f"changes {b.changes()}")
    rows(&db)
    let h = handle_of(&db)
    print(f"handle changes {h.changes()}")
    print("ok")
