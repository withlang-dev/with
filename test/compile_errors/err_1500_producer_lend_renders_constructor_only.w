//! expect-check-fail: wrong argument type in call to 'Database.prepare'

// #1500 (§16.2b.3/§16.2b.4, ruling §9): an fn item with `lend` that describes
// a resource's producer (`from db_prepare(out param 2)`) covers that
// producer's remaining raw parameters and renders the constructor only. It
// once also rendered a safe lend method on the parent that handed C the
// caller's own out slot — `Database.db_prepare(sql, out, tail)`, a second
// call surface producing an unowned, never-finalized statement. The one
// `prepare` on Database is the producer's receiver form `(sql, tail)`; a
// call passing an out slot is refused.

use c_import("typedef struct db db;
typedef struct st st;
int db_open(const char *name, db **out);
int db_close(db *d);
int db_prepare(db *d, const char *sql, st **out, const char **tail);
int st_finalize(st *s);
")

c facade dbf:
    resource Database wraps *mut db
        from db_open(out param 1)
        drop db_close
    resource Statement wraps *mut st
        from db_prepare(out param 2)
        drop st_finalize
        borrows param 0
    fn db_prepare
        lend

fn prepare_raw(d: &Database):
    var slot: *mut st = null
    var tail: *const i8 = null
    let (rc, _) = d.prepare("select 1", &raw mut slot, &raw mut tail)
    print(rc)

fn main:
    print("ok")
