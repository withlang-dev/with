//! expect-check-fail: fn 'db_by_name': 'returns borrow Database from param 0' names param 0: *const i8 name, which receives no modeled resource, and With does not invent an origin (§16.2b.7)

// D51 stage 6 (ruling §26, §31): a borrowed return's origin parameter must
// receive a modeled resource.

use c_import("typedef struct db db;
db* db_new(int flags);
void db_close(db* d);
db* db_by_name(const char* name);
")

c facade dep:
    resource Database wraps *mut db
        from db_new
        drop db_close
    fn db_by_name
        returns borrow Database from param 0

fn main:
    print("x")
