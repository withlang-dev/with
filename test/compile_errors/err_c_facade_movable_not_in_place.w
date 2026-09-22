//! expect-check-fail: 'movable' releases the pinning of an in-place resource, and this resource has no 'init'

// Spec §16.2b.3, D54: `movable` is the facade's claim that no operation
// keeps an in-place representation's address. A pointer or by-value
// resource is not pinned to begin with, so the clause states nothing.

use c_import("typedef struct db db;
db* db_new(int flags);
void db_close(db* d);
")

c facade dbl:
    resource Database wraps *mut db
        movable
        from db_new
        drop db_close

fn main:
    print("ok")
