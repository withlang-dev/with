//! expect-check-fail: fn 'cur_db' returns a borrowed 'Database' from a 'Cursor', and fn 'st_db' from a 'Statement'; 'BorrowedDatabase' holds a view of one origin resource, and a borrowed value with several origin types is not ruled (§16.2b.6)

// D51 stage 6 (ruling §26): `Borrowed<R>` holds a view of one origin
// resource; two operations borrowing R from different resources are refused
// rather than given a second type.

use c_import("typedef struct db db;
typedef struct st st;
typedef struct cur cur;
db* db_new(int flags);
void db_close(db* d);
st* st_new(db* d, int n);
void st_free(st* s);
cur* cur_new(db* d, int n);
void cur_free(cur* c);
db* st_db(st* s);
db* cur_db(cur* c);
")

c facade dep:
    resource Database wraps *mut db
        from db_new
        drop db_close
    resource Statement wraps *mut st
        from st_new
        drop st_free
    resource Cursor wraps *mut cur
        from cur_new
        drop cur_free
    fn st_db
        returns borrow Database from param 0
    fn cur_db
        returns borrow Database from param 0

fn main:
    print("x")
