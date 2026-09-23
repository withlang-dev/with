//! expect-check-fail: 'DatabaseError', the error type of its 'ok DB_OK' projection, and test/compile_errors/err_c_facade_generated_name_facade_resource.w:22:5 declares the resource 'DatabaseError'

// D51 stage 5 (Eric, 2026-09-23, on #1426): a facade that declares a
// resource named like another resource's generated error type — `Database`
// with `ok` renders `DatabaseError` — collides with itself; the error names
// both.

use c_import("typedef struct db db;
typedef struct dberr dberr;
#define DB_OK 0
int db_open(const char* path, db** out);
void db_close(db* d);
dberr* dberr_new(int code);
void dberr_free(dberr* e);
")

c facade dbl:
    resource Database wraps *mut db
        from db_open(out param 1)
        drop db_close
        ok DB_OK
    resource DatabaseError wraps *mut dberr
        from dberr_new
        drop dberr_free

fn main:
    print("ok")
