//! expect-check-fail: 'ok DB_OK' compares an integer status, but producer 'db_open' returns f64

// D51 stage 5, spec §16.2b.4/§16.2b.13: `ok` compares the status with an
// imported integer constant, so the status is an integer (a C enum is one).

use c_import("typedef struct db db;
#define DB_OK 0
double db_open(const char* path, db** out);
void db_close(db* d);
")

c facade dbl:
    resource Database wraps *mut db
        from db_open(out param 1)
        drop db_close
        ok DB_OK

fn main:
    print("ok")
