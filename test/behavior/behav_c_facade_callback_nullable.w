//! expect-stdout: with callback 101
//! expect-stdout: with closure 200
//! expect-stdout: without callback -1
//! expect-stdout: ok

// D51 stage 12b (#1618; ruling §43-§44, spec §16.2b.8-9): a callback the
// facade states `nullable` is `Option[extern "C" fn(&U, …)]`, and its
// userdata — what the callback receives — `Option[&U]`: absent with it.
// `db_exec(db *, db_cb cb, void *ud, int n)` declares no nullability, so
// the facade does (§43: where the header does not establish it, the
// facade must), and `d.exec(None, None, n)` hands C a NULL callback and a
// NULL userdata; `d.exec(Some(on), Some(&ctx), n)` is the call with one,
// the callback still a captureless fn or closure (§12.4). `U` is bound by
// the userdata given, or Unit when none is (nothing reads it).
use c_import("#include <stdlib.h>
typedef int (*db_cb)(void *ud, int n);
typedef struct db { int total; } db;
static inline db *db_new(int n) { db *d = (db *)malloc(sizeof(db)); d->total = n; return d; }
static inline void db_close(db *d) { free(d); }
static inline int db_exec(db *d, db_cb cb, void *ud, int n) { if (!cb) return ud ? -2 : -1; int r = cb(ud, n); d->total += r; return r; }
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
    let ctx = Ctx { base: 100 }
    print(f"with callback {d.exec(Some(on), Some(&ctx), 1)}")
    print(f"with closure {d.exec(Some((c, n) => c.base * n), Some(&ctx), 2)}")
    print(f"without callback {d.exec(None, None, 3)}")
    print("ok")
