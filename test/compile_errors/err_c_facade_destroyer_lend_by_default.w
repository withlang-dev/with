//! expect-check-fail: 'db_close_v2' destroys the resource but the fn item describing it lends its parameters

// D51 §16.2b.3 / ruling §9: an fn item lends its parameters by default
// (§16.2b.5), so describing a `destroys` operation only for presentation
// (`of`, `rename`) without stating `destroys` makes it callable as a lend.

use c_import("typedef struct db db;
db* db_new(int flags);
void db_close(db* d);
int db_close_v2(db* d, int how);
")

c facade dbl:
    resource Database wraps *mut db
        from db_new
        drop db_close
        destroys db_close_v2
    fn db_close_v2
        of Database
        rename close

fn main:
    print("ok")
