//! expect-check-fail: tuple pattern requires tuple subject

// D51 stage 5 (Eric, 2026-09-23, on #1426): one call surface per production
// form. With `ok` stated, the out-parameter producer's constructor is the
// Result projection; the low-level `(status, Option[R])` pair is not rendered
// beside it, so the tuple spelling does not type-check.

use c_import("typedef struct db db;
#define DB_OK 0
int db_open(const char* path, db** out);
void db_close(db* d);
")

c facade dbl:
    resource Database wraps *mut db
        from db_open(out param 1)
        drop db_close
        ok DB_OK

fn main:
    let (status, db) = Database.open("x.db")
    print(f"{status} {db.is_some()}")
