//! expect-check-fail: 'ok DB_OK' reads producer 'db_open''s status as i32 and producer 'db_open_ex''s as i64

// D51 stage 5: `ok` projects every status-returning producer of a resource
// onto one `Result[R, <R>Error]`, and that error type carries a status of
// one type; producers whose statuses have different types cannot share it.

use c_import("typedef struct db db;
#define DB_OK 0
int db_open(const char* path, db** out);
long long db_open_ex(const char* path, db** out);
void db_close(db* d);
")

c facade dbl:
    resource Database wraps *mut db
        from db_open(out param 1)
        from db_open_ex(out param 1)
        drop db_close
        ok DB_OK

fn main:
    print("ok")
