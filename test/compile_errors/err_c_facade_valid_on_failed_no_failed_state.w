//! expect-check-fail: fn 'db_count': 'valid on failed', but 'Database' has no failed state

// D51 stage 12b (#1612; spec §16.2b.4): `valid on failed` marks an
// operation of a failed-state resource, and only an out-parameter producer
// under `ok` of a resource that depends on nothing can fail and still
// produce one. A direct-return producer yields `Option[Database]` — a NULL
// produced nothing — so there is no failed state to be valid on, and the
// mark is refused rather than ignored.
use c_import("typedef struct db db;
db* db_new(int n);
void db_close(db* d);
int db_count(db* d);
")

c facade dbz:
    resource Database wraps *mut db
        from db_new
        drop db_close
    fn db_count
        lend
        valid on failed

fn main:
    print("unreachable")
