//! expect-check-fail: 'ok' is stated twice; list every success status in one clause

// Spec §16.2b.4 (ruling Amendment 1, #1432): a producer's success statuses
// are one `ok` clause, `ok C1, C2`. A second clause is refused, never
// silently read in place of the first.
use c_import("typedef struct db db;\n#define DB_OK 0\n#define DB_READONLY 7\nint db_open(const char* path, db** out);\nvoid db_close(db* d);\n")

c facade dbl:
    resource Database wraps *mut db
        from db_open(out param 1)
        drop db_close
        ok DB_OK
        ok DB_READONLY

fn main:
    print("unreachable")
