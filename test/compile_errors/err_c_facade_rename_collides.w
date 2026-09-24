//! expect-check-fail: resource 'Database': 'db_size' is renamed 'count', and 'count' is presented as 'count' on 'Database' too; two operations of one resource cannot share a name — rename one (§16.2b.11)

// D51 stage 8 (spec §16.2b.11): a `rename` is explicit and never yields to
// the convention; two explicit spellings of one name on one resource are
// the facade saying two things, an error naming both.

use c_import("typedef struct db db;
db* db_new(int n);
void db_close(db* d);
int db_size(db* d);
int count(db* d);
")

c facade dbf:
    resource Database wraps *mut db
        from db_new
        drop db_close
    fn db_size
        rename count
    fn count

fn main:
    print("x")
