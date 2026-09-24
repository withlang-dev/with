//! expect-stdout: 3 4 5
//! expect-stdout: ok

// D51 stage 8 (ruling §55, spec §16.2b.11): "Where automatic grouping is
// ambiguous the sugar is omitted and the operation remains available under
// its imported name." `db_get` would shorten to `get`, the imported name of
// another lend of the same resource, and `db_drop` to `drop`, the
// resource's Drop: each keeps its imported name, the compiler never picks,
// and the warning names the candidates and the `rename` that settles it
// (pinned by behav_c_facade_presentation_ambiguous_warns.w).
// `db_count` is unambiguous and is `count`.

use c_import("#include <stdlib.h>
typedef struct db { int n; } db;
static inline db *db_new(int n) { db *d = (db *)malloc(sizeof(db)); d->n = n; return d; }
static inline void db_close(db *d) { free(d); }
static inline int db_get(db *d) { return d->n; }
static inline int get(db *d) { return d->n + 1; }
static inline int db_drop(db *d) { return d->n + 2; }
static inline int db_count(db *d) { return d->n; }
")

c facade dbf:
    resource Database wraps *mut db
        from db_new
        drop db_close
    fn db_get
    fn get
    fn db_drop
    fn db_count

fn main:
    let d = Database.new(3).unwrap()
    print(f"{d.db_get()} {d.get()} {d.db_drop()}")
    if d.count() == 3: print("ok")
