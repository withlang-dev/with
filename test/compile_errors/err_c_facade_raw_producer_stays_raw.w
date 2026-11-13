//! expect-check-fail: raw c_import function call requires unsafe context: `db_new` is the producer of `Database`; write `Database.new(…)`

// §31.4: a function a contract names is described, and the base rule does
// not apply to it. A resource's producer is reached as the resource's
// constructor, which owns what it produces; by its C name it is a raw call
// (a safe `db_new(1)` would hand back a pointer nothing destroys), and the
// error names the presented spelling.

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
