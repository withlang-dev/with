//! expect-check-fail: fn 'st_step': 'of Database' assigns it to a resource param 0: *mut st s does not receive; it receives 'Statement' — state 'of Statement' (§16.2b.3)

// D51 stage 8 (ruling §53, §61): `of` assigns an operation to a resource
// its first parameter receives; naming one it does not is a facade
// statement that does not verify.

use c_import("typedef struct db db;
typedef struct st st;
db* db_new(int n);
void db_close(db* d);
st* st_new(db* d, int id);
void st_finalize(st* s);
int st_step(st* s);
")

c facade dbf:
    resource Database wraps *mut db
        from db_new
        drop db_close
    resource Statement wraps *mut st
        from st_new
        drop st_finalize
    fn st_step
        of Database

fn main:
    print("x")
