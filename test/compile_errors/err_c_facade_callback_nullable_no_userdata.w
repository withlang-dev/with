//! expect-check-fail: 'db_exec': a callback given with no userdata; the callback receives its userdata ('callback param N userdata param M'), so pass one, or None for both when no callback is wanted (§16.2b.9)

// D51 stage 12b (#1618; spec §16.2b.9): a nullable callback is absent with
// its userdata, or present with it. A callback given with `None` for the
// userdata is the pairing violated — the callback would receive a NULL
// where it was promised a `&U` — and is refused at the call, naming the
// pairing rather than a type mismatch.
use c_import("#include <stdlib.h>
typedef int (*db_cb)(void *ud, int n);
typedef struct db { int total; } db;
static inline db *db_new(int n) { db *d = (db *)malloc(sizeof(db)); d->total = n; return d; }
static inline void db_close(db *d) { free(d); }
static inline int db_exec(db *d, db_cb cb, void *ud, int n) { if (!cb) return -1; return cb(ud, n); }
")

c facade dbn:
    resource Database wraps *mut db
        from db_new
        drop db_close
    fn db_exec
        callback param 1 userdata param 2
        nullable param 1

type Ctx { base: i32 }
fn on(c: &Ctx, n: c_int) -> c_int: c.base + n

fn main:
    let d = Database.new(0).unwrap()
    print(f"{d.exec(Some(on), None, 1)}")
