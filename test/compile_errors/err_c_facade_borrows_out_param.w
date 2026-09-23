//! expect-check-fail: resource 'Statement': 'borrows' names param 1: *mut *mut st out of 'st_open', the out parameter the resource is produced through

// D51 stage 6 (ruling §61): `borrows` names a parent the producer receives,
// never the slot the resource itself is produced through.

use c_import("typedef struct db db;
typedef struct st st;
db* db_new(int flags);
void db_close(db* d);
int st_open(db* d, st** out);
void st_free(st* s);
")

c facade dep:
    resource Database wraps *mut db
        from db_new
        drop db_close
    resource Statement wraps *mut st
        from st_open(out param out)
        drop st_free
        borrows param 1

fn main:
    print("x")
