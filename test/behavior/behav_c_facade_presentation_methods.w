//! expect-stdout: prepared 105 205
//! expect-stdout: count 2 length 9
//! expect-stdout: shut 1
//! expect-stdout: ok

// D51 stage 8 (ruling §53-§55, spec §16.2b.11): every operation a resource
// exposes is spelled on the resource type by the naming convention — the
// C name less the representation's prefix. `db_new` on `Database wraps
// *mut db` is `Database.new`, the lend `db_count` is `d.count()`, the
// destroyer `db_shutdown` is `d.shutdown()`, and a producer received
// through the database, `db_prepare(db *, …)`, is presented as `d.prepare(…)`
// beside the constructor `Statement.prepare(d, …)` (ruling §54:
// `sqlite3_prepare_v2(db, …)` "may be presented as db.prepare(...)"). A
// `rename` overrides the convention (`db_size` is `length`). Presentation
// changes spellings only: the dependent statement is still dropped before
// its database, and the destroyer still consumes.

use c_import("#include <stdlib.h>
typedef struct db { int n; int shut; } db;
typedef struct st { db *owner; int id; } st;
static inline db *db_new(int n) { db *d = (db *)malloc(sizeof(db)); d->n = n; d->shut = 0; return d; }
static inline void db_close(db *d) { free(d); }
static inline int db_shutdown(db *d, int how) { int r = d->shut + how; free(d); return r; }
static inline int db_count(db *d) { return d->n; }
static inline int db_size(db *d, int k) { return d->n + k; }
static inline st *db_prepare(db *d, int id) { st *s = (st *)malloc(sizeof(st)); s->owner = d; s->id = id; return s; }
static inline void st_finalize(st *s) { free(s); }
static inline int st_step(st *s) { return s->owner->n * 100 + s->id; }
")

c facade dbf:
    resource Database wraps *mut db
        from db_new
        drop db_close
        destroys db_shutdown
    resource Statement wraps *mut st
        from db_prepare
        drop st_finalize
    fn db_count
        lend
    fn db_size
        rename length
    fn st_step

fn main:
    let d = Database.new(1).unwrap()
    let a = d.prepare(5).unwrap()
    let b = Statement.prepare(d, 5).unwrap()
    let d2 = Database.new(2).unwrap()
    let c = d2.prepare(5).unwrap()
    print(f"prepared {a.step()} {c.step()}")
    print(f"count {d2.count()} length {d2.length(7)}")
    drop(c)
    let shut = d2.shutdown(1)
    print(f"shut {shut}")
    drop(a)
    drop(b)
    print("ok")
