//! expect-check-fail: resource 'Database' renders 'FailedDatabase', the type of a resource a failed producer still produced, and

// D51 stage 5 (Eric, 2026-09-23, on #1426): `ok` over an out-parameter
// producer renders `<R>Error` and `Failed<R>` beside the resource. A type of
// either name declared in the facade's own module is a compile-time error
// naming both (the §10.9/D57 collision rule at the type level): the compiler
// never picks between two types of one name.

use c_import("typedef struct db db;
#define DB_OK 0
int db_open(const char* path, db** out);
void db_close(db* d);
")

type FailedDatabase {
    reason: str,
}

c facade dbl:
    resource Database wraps *mut db
        from db_open(out param 1)
        drop db_close
        ok DB_OK

fn main:
    print("ok")
