//! expect-check-fail: resource 'Database' has 'destroys' operations but no 'drop'; every destroyer takes further arguments, so name a 'drop' operation or model the representation differently

// Ruling (Eric, 2026-09-22): a resource with `destroys` operations and no
// `drop` is a compile error; when no destroyer is unary there is nothing to
// suggest, and the diagnostic says so.

use c_import("typedef struct db db;\ndb* db_new(int id);\nint db_close_v2(db* d, int how);\nint db_close_v3(db* d, int how, int why);\n")

c facade dbl:
    resource Database wraps *mut db
        from db_new
        destroys db_close_v2
        destroys db_close_v3
    fn db_close_v2
        destroys
    fn db_close_v3
        destroys

fn main:
    print("ok")
