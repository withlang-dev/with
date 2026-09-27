//! expect-stdout: open 0: status=0 ok=true count=0
//! expect-stdout: open 1: status=7 readonly=true count=1
//! expect-stdout: open 2: failed status=5 produced
//! expect-stdout: open 9: failed status=5 nothing produced
//! expect-stdout: sum 1: 8
//! expect-stdout: sum 2: failed
//! expect-stdout: init 0: status=0 state=10
//! expect-stdout: init 1: status=3 state=11
//! expect-stdout: init 2: failed status=-1
//! expect-stdout: ok

// Spec §16.2b.4 (D71, ruling Amendment 1, #1432): a producer's `ok` may list
// several compile-time constants; any of them is success, and the `Ok` side
// carries the status that matched beside the produced value, as
// `(status, R)` — the order of the pair the facade renders without `ok`.
// A status outside the list is a failure, with or without a produced
// resource; `?` propagates it like any other error. Both production forms
// that read a status: an out parameter (`Database.open`) and in place
// (`Stream.init`).

use c_import("#include <stdlib.h>
#define DB_OK 0
#define DB_READONLY 7
#define DB_BUSY 5
typedef struct db { int n; } db;
static inline int db_open(int n, db **out) {
    if (n == 9) { *out = 0; return DB_BUSY; }
    db *d = (db *)malloc(sizeof(db)); d->n = n; *out = d;
    return n == 0 ? DB_OK : n == 1 ? DB_READONLY : DB_BUSY;
}
static inline void db_close(db *d) { free(d); }
static inline int db_count(db *d) { return d->n; }
#define S_OK 0
#define S_PARTIAL 3
typedef struct stream { int state; } stream;
static inline int stream_init(stream *s, int mode) { s->state = 10 + mode; return mode == 0 ? S_OK : mode == 1 ? S_PARTIAL : -1; }
static inline void stream_end(stream *s) { s->state = 0; }
static inline int stream_state(stream *s) { return s->state; }
")

c facade several:
    resource Database wraps *mut db
        from db_open(out param 1)
        drop db_close
        ok DB_OK, DB_READONLY
    resource Stream wraps stream
        init stream_init(self)
        drop stream_end
        ok S_OK, S_PARTIAL
    fn db_count
        lend
    fn stream_state
        lend

fn sum(n: i32) -> Result[i32, DatabaseError]:
    let (status, d) = Database.open(n)?
    status + d.count()

fn main:
    match Database.open(0):
        Ok((status, d)) => print(f"open 0: status={status} ok={status == DB_OK} count={d.count()}")
        Err(e) => print(f"unexpected {e:?}")
    match Database.open(1):
        Ok((status, d)) => print(f"open 1: status={status} readonly={status == DB_READONLY} count={d.count()}")
        Err(e) => print(f"unexpected {e:?}")
    match Database.open(2):
        Err(DatabaseError.FailedWithResource(status, _)) => print(f"open 2: failed status={status} produced")
        _ => print("unexpected")
    match Database.open(9):
        Err(DatabaseError.Failed(status)) => print(f"open 9: failed status={status} nothing produced")
        _ => print("unexpected")
    match sum(1):
        Ok(v) => print(f"sum 1: {v}")
        Err(_) => print("sum 1: failed")
    match sum(2):
        Ok(v) => print(f"sum 2: {v}")
        Err(_) => print("sum 2: failed")
    match Stream.init(0):
        Ok((status, s)) => print(f"init 0: status={status} state={s.state()}")
        Err(_) => print("unexpected")
    match Stream.init(1):
        Ok((status, s)) => print(f"init 1: status={status} state={s.state()}")
        Err(_) => print("unexpected")
    match Stream.init(2):
        Err(StreamError.Failed(status)) => print(f"init 2: failed status={status}")
        _ => print("unexpected")
    print("ok")
