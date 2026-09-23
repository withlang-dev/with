//! expect-check-fail: err_c_facade_resource_diag_location.w:19:5

// A resource-level facade diagnostic points at the resource in the file that
// declares it — not into the rendered `<facade NAME>` text the last pass
// visited, whose line it used to quote (ruling §8: diagnostics carry the
// fact's provenance).

use c_import("typedef struct db db;
typedef struct st st;
db* db_new(int flags);
void db_close(db* d);
st* st_new(int n);
")

c facade dbl:
    resource Database wraps *mut db
        from db_new
        drop db_close
    resource Statement wraps *mut st
        from st_new

fn main:
    print("ok")
