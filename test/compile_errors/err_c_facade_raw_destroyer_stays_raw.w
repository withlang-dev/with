//! expect-check-fail: raw c_import function call requires unsafe context

// D51 §16.2b.5: "destroy through C, then Drop destroys again" is not
// expressible in safe code. A resource is the safe surface of its
// representation — its Drop and destroyers call the C operation inside
// `unsafe {}` — and never lifts the raw C name: `db_close(d.repr)` in safe
// code would close the handle Drop closes again.

use c_import("typedef struct db db;
db* db_new(int flags);
void db_close(db* d);
")

c facade dbl:
    resource Database wraps *mut db
        from db_new
        drop db_close

fn main:
    let p: *mut db = null
    db_close(p)
