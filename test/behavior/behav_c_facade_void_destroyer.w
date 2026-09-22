//! expect-stdout: mut 1
//! expect-stdout: const 1
//! expect-stdout: alias 1
//! expect-stdout: destroys 7 1
//! expect-stdout: ok

// Ruling §61 (Eric, 2026-09-22): "the destroyer accepts the representation"
// is C's own conversion rule — a `void *` destroyer (`free`) accepts every
// object pointer representation: `*mut T`, `*const T`, and a typedef'd
// pointer chased through its alias. Each C object counts its own
// destructions and is the witness that Drop ran the void-pointer destroyer
// exactly once. No `unsafe` in the resource operations.

use c_import("void *malloc(unsigned long size);
typedef struct db { int id; int closed; } db;
typedef db* dbp;
static inline db* db_new(int id) { db* d = (db*)malloc(sizeof(db)); d->id = id; d->closed = 0; return d; }
static inline const db* db_new_const(int id) { return db_new(id); }
static inline dbp db_new_alias(int id) { return db_new(id); }
static inline void release(void* p) { ((db*)p)->closed++; }
static inline void release_const(const void* p) { ((db*)p)->closed++; }
static inline int release_how(void* p, int how) { ((db*)p)->closed++; return how; }
static inline int db_closed(const db* d) { return d->closed; }
")

c facade dbl:
    resource Database wraps *mut db
        from db_new
        drop release
        destroys release_how
    resource View wraps *const db
        from db_new_const
        drop release
    resource Alias wraps dbp
        from db_new_alias
        drop release_const
    fn release_how
        destroys

fn main:
    let a = Database.db_new(1)
    let pa = a.repr
    drop(a)
    unsafe { print(f"mut {db_closed(pa)}") }
    let v = View.db_new_const(2)
    let pv = v.repr
    drop(v)
    unsafe { print(f"const {db_closed(pv)}") }
    let l = Alias.db_new_alias(3)
    let pl = l.repr
    drop(l)
    unsafe { print(f"alias {db_closed(pl)}") }
    let d = Database.db_new(4)
    let pd = d.repr
    let how = d.release_how(7)
    unsafe { print(f"destroys {how} {db_closed(pd)}") }
    print("ok")
