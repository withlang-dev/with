//! expect-check-fail: resource 'Database': 'db_count' is not an imported compile-time constant

// Spec §16.2b.4, §16.2b.13 (ruling Amendment 1, #1432): every success status
// an `ok` list names is verified as an imported compile-time constant, not
// only the first.
use c_import("typedef struct db db;\n#define DB_OK 0\nint db_open(const char* path, db** out);\nvoid db_close(db* d);\nint db_count(db* d);\n")

c facade dbl:
    resource Database wraps *mut db
        from db_open(out param 1)
        drop db_close
        ok DB_OK, db_count

fn main:
    print("unreachable")
