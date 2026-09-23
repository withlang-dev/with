//! expect-stdout: produced status=0 some=true closes=0
//! expect-stdout: dropped closes=1
//! expect-stdout: failed status=-1 some=false closes=1
//! expect-stdout: failed but produced status=14 some=true closes=1
//! expect-stdout: failure handle closed closes=2
//! expect-stdout: succeeded without producing status=0 some=false closes=2
//! expect-stdout: void producer some=true closes=2
//! expect-stdout: void producer none some=false closes=3
//! expect-stdout: moved through calls closes=3
//! expect-stdout: dropped after moves closes=4
//! expect-stdout: slots null on entry dirty=0
//! expect-stdout: ok

// D51 stage 5, ruling §15-§18, spec §16.2b.4: out-parameter production. The
// constructor initializes the slot to NULL, calls, and inspects the slot:
// non-null is a produced resource owned at once, null is none — production,
// not success. With no `ok` the status is uninterpreted and handed back
// beside it, `(status, Option[R])`, so every combination is kept: success
// with a handle, failure with none, failure that still produced a handle
// (SQLite's failed open: the handle is the caller's, and its Drop closes it
// exactly once), and success that produced nothing (sqlite3_prepare_v2 over
// an empty statement). A producer returning nothing yields `Option[R]`. The
// C side counts closes and counts every call whose slot was not NULL on
// entry.

use c_import("void *malloc(unsigned long size);
void *calloc(unsigned long count, unsigned long size);
void free(void *p);
typedef struct { int* closes; int* dirty; } Counter;
typedef struct db { Counter c; } db;
static inline Counter counter_new(void) { Counter c; c.closes = (int*)calloc(1, sizeof(int)); c.dirty = (int*)calloc(1, sizeof(int)); return c; }
static inline int counter_closes(Counter c) { return *c.closes; }
static inline int counter_dirty(Counter c) { return *c.dirty; }
static inline void counter_free(Counter c) { free(c.closes); free(c.dirty); }
static inline db* db_alloc(Counter c) { db* d = (db*)malloc(sizeof(db)); d->c = c; return d; }
static inline int db_open(Counter c, int mode, db** out) {
    if (*out != 0) { *c.dirty = *c.dirty + 1; }
    if (mode == 1) { return -1; }
    if (mode == 3) { return 0; }
    *out = db_alloc(c);
    if (mode == 2) { return 14; }
    return 0;
}
static inline void db_make(Counter c, int produce, db** out) {
    if (*out != 0) { *c.dirty = *c.dirty + 1; }
    if (produce != 0) { *out = db_alloc(c); }
}
static inline void db_close(db* d) { *d->c.closes = *d->c.closes + 1; free(d); }
")

c facade dbl:
    resource Database wraps *mut db
        from db_open(out param out)
        from db_make(out param 2)
        drop db_close

fn keep(d: Database) -> Database: d

fn opened(c: Counter) -> Database:
    let (_, d) = Database.db_open(c, 0)
    d.unwrap()

fn main:
    let c = counter_new()
    let (st, made) = Database.db_open(c, 0)
    print(f"produced status={st} some={made.is_some()} closes={counter_closes(c)}")
    drop(made)
    print(f"dropped closes={counter_closes(c)}")
    let (fst, failed) = Database.db_open(c, 1)
    print(f"failed status={fst} some={failed.is_some()} closes={counter_closes(c)}")
    let (pst, produced) = Database.db_open(c, 2)
    print(f"failed but produced status={pst} some={produced.is_some()} closes={counter_closes(c)}")
    drop(produced)
    print(f"failure handle closed closes={counter_closes(c)}")
    let (ost, nothing) = Database.db_open(c, 3)
    print(f"succeeded without producing status={ost} some={nothing.is_some()} closes={counter_closes(c)}")
    let v = Database.db_make(c, 1)
    print(f"void producer some={v.is_some()} closes={counter_closes(c)}")
    drop(v)
    let none = Database.db_make(c, 0)
    print(f"void producer none some={none.is_some()} closes={counter_closes(c)}")
    let kept = keep(opened(c))
    print(f"moved through calls closes={counter_closes(c)}")
    drop(kept)
    print(f"dropped after moves closes={counter_closes(c)}")
    print(f"slots null on entry dirty={counter_dirty(c)}")
    counter_free(c)
    print("ok")
