//! expect-check-fail: raw c_import function call requires unsafe context

// D51 §16.2b.5: a lend of a resource is safe because With proves the
// resource live, unmoved and undestroyed — which it cannot prove of a raw
// pointer. The lend is rendered as the method `d.count()`; the C name
// called on a raw pointer stays raw (a null or dangling handle would reach C).

use c_import("typedef struct db db;
db* db_new(int flags);
void db_close(db* d);
int db_count(db* d);
")

c facade dbl:
    resource Database wraps *mut db
        from db_new
        drop db_close
    fn db_count
        lend

fn main:
    let p: *mut db = null
    let n = db_count(p)
