//! expect-check-fail: unknown method 'db_count' for type 'Database'

// D51 stage 8 (spec §16.2b.11): a presented operation has one spelling on
// the resource, its presented name (`d.count()`); the imported name is the
// raw C surface, not a second method.

use c_import("typedef struct db db;
db* db_new(int n);
void db_close(db* d);
int db_count(db* d);
")

c facade dbf:
    resource Database wraps *mut db
        from db_new
        drop db_close
    fn db_count

fn main:
    let d = Database.new(1).unwrap()
    let n = d.db_count()
