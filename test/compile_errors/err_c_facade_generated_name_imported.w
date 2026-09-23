//! expect-check-fail: errors.w:4:1 declares a type 'DatabaseError', which this module imports

// D51 stage 5 (Eric, 2026-09-23, on #1426): `ok` renders `<R>Error` beside
// the resource. When the facade's module already sees a type of that name
// through an import, the compiler never picks between them — the §10.9/D57
// rule for a written variant colliding with a generated one, at the type
// level. The error names both declarations.

use c_import("typedef struct db db;
#define DB_OK 0
int db_open(const char* path, db** out);
void db_close(db* d);
")
use facade_names.errors

c facade dbl:
    resource Database wraps *mut db
        from db_open(out param 1)
        drop db_close
        ok DB_OK

fn main:
    print("ok")
