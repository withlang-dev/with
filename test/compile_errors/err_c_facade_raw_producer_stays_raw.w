//! expect-check-fail: raw c_import function call requires unsafe context

// D51 §16.2b.3/§16.2b.5: a resource's producer is safe through the
// resource's constructor, which owns what it produces. The raw C name stays
// raw: a safe `db_new(1)` would hand back a pointer nothing destroys — a
// safe constructor with no destruction contract.

use c_import("typedef struct db db;
db* db_new(int flags);
void db_close(db* d);
")

c facade dbl:
    resource Database wraps *mut db
        from db_new
        drop db_close

fn main:
    let p = db_new(1)
