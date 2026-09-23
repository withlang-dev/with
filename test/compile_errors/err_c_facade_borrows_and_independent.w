//! expect-check-fail: resource 'Statement' states both 'independent' and 'borrows'

// D51 stage 6 (ruling §61; spec §16.2b.6): `independent` says the resource
// depends on nothing its producers receive and `borrows` names what it
// depends on — a facade stating both is refused.

use c_import("typedef struct db db;
typedef struct st st;
db* db_new(int flags);
void db_close(db* d);
st* st_new(db* d, int n);
void st_free(st* s);
")

c facade dep:
    resource Database wraps *mut db
        from db_new
        drop db_close
    resource Statement wraps *mut st
        from st_new
        drop st_free
        borrows param 0
        independent

fn main:
    print("x")
