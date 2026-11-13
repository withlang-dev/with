//! expect-check-fail: raw c_import function call requires unsafe context

// D51 §16.2b.3/§16.2b.5: a resource's producer is safe through the
// resource's constructor, which owns what it produces. The raw C name gives
// the raw pointer, which is inert (§31.4): safe code cannot hand it back to
// C, so it cannot be closed, read or used as a `Database`.

use c_import("typedef struct db db;
db* db_new(int flags);
void db_close(db* d);
")

c contract dbl:
    resource Database wraps *mut db
        from db_new
        drop db_close

fn main:
    let p = db_new(1)
    db_close(p)
