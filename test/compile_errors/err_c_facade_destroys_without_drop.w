//! expect-check-fail: = help: name the unary destroyer as the drop operation: 'drop db_close'

// Ruling (Eric, 2026-09-22): a resource with `destroys` operations and no
// `drop` is a compile error — never half-model unsafely: a value dropped
// while live would leak silently. Exactly one destroyer is unary here, so
// the diagnostic suggests it. (Must-consume linear resources are a future
// ruling, not this one.)

use c_import("typedef struct db db;\ndb* db_new(int id);\nvoid db_close(db* d);\nint db_close_v2(db* d, int how);\n")

c facade dbl:
    resource Database wraps *mut db
        from db_new
        destroys db_close
        destroys db_close_v2
    fn db_close
        destroys
    fn db_close_v2
        destroys

fn main:
    print("ok")
