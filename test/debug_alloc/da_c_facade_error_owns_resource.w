//! expect-debug-alloc: leak count=0
// D51 stage 5 (Eric, 2026-09-23, on #1426): `ok` projects an out-parameter
// producer onto `Result[Database, DatabaseError]`, and a failure that still
// produced (SQLite's failed open) is `DatabaseError.FailedWithResource`,
// which owns the failed handle as a `FailedDatabase`. It is the first error
// type with a destructor, so `?` moving it up through frames — here through
// two — must move that ownership, never copy it: dropping the error at the
// top destroys the handle exactly once. Matched and taken out of the error,
// the handle is destroyed once by its new owner. (Converting it into a
// wider error with §10.9 `error AppError from DatabaseError` is not in this
// fixture: a user enum declared before a rendered one it carries is
// mis-laid-out by codegen, #1430.) The C side counts closes (the destroy
// witness, asserted inline — a clean fixture must exit 0) and its `malloc`
// and `free` are translated into the program, so the ledger sees every
// handle: a missed destroy is a LEAK, a second one a DOUBLE FREE. Raw access
// to the failed handle's representation compiles under the raw C rules.
// Constructors keep the C name (`Database.db_open`); presentation is
// §16.2b.11, stage 8.
use c_import("void *malloc(unsigned long size);
void *calloc(unsigned long count, unsigned long size);
void free(void *p);
#define DB_OK 0
typedef struct { int* n; } Counter;
static inline Counter counter_new(void) { Counter c; c.n = (int*)calloc(1, sizeof(int)); return c; }
static inline int counter_get(Counter c) { return *c.n; }
static inline void counter_free(Counter c) { free(c.n); }
typedef struct db { int tag; Counter closes; } db;
static inline int db_open(Counter closes, int mode, db** out) {
    if (mode == 1) { return 5; }
    if (mode == 3) { return DB_OK; }
    db* d = (db*)malloc(sizeof(db)); d->tag = mode; d->closes = closes; *out = d;
    if (mode == 2) { return 14; }
    return DB_OK;
}
static inline void db_close(db* d) { *d->closes.n = *d->closes.n + 1; free(d); }
static inline int db_tag(db* d) { return d->tag; }
")

c facade dbf:
    resource Database wraps *mut db
        from db_open(out param 2)
        drop db_close
        ok DB_OK

fn open(closes: Counter, mode: c_int) -> Result[Database, DatabaseError]:
    let db = Database.db_open(closes, mode)?
    Ok(db)

fn tag_of(closes: Counter, mode: c_int) -> Result[c_int, DatabaseError]:
    let db = open(closes, mode)?
    Ok(unsafe { db_tag(db.repr) })

fn main:
    let closes = counter_new()
    // Propagated through two frames by `?`, then dropped.
    let up = tag_of(closes, 2)
    assert(up.is_err())
    assert(counter_get(closes) == 0)
    drop(up)
    assert(counter_get(closes) == 1)
    // Matched and taken out: the new owner destroys it.
    var kept: Vec[FailedDatabase] = Vec.new()
    match open(closes, 2):
        Err(DatabaseError.FailedWithResource(status, failed)) =>
            assert(status == 14)
            assert(unsafe { db_tag(failed.repr) } == 2)
            kept.push(failed)
        _ => assert(false)
    assert(counter_get(closes) == 1)
    drop(kept)
    assert(counter_get(closes) == 2)
    // Success, a failure that produced nothing, success that produced nothing.
    assert(tag_of(closes, 0).unwrap() == 0)
    assert(counter_get(closes) == 3)
    match open(closes, 1):
        Err(DatabaseError.Failed(status)) => assert(status == 5)
        _ => assert(false)
    match open(closes, 3):
        Err(DatabaseError.NothingProduced(status)) => assert(status == 0)
        _ => assert(false)
    assert(counter_get(closes) == 3)
    counter_free(closes)
    print("ok")
