//! expect-check-fail: resource 'Statement': producer 'st_new' receives param 0: *mut db d, a representation several resources wrap ('Reader', 'Writer'); the constructor cannot tell which resource it borrows (§16.2b.3)

// D51 stage 6 (ruling §14, §27): two resources wrap `*mut db`, so a producer
// receiving one is not assigned to either; the constructor would have to
// pick the resource it borrows, and the compiler never picks. Both
// candidates are named.

use c_import("typedef struct db db;
typedef struct st st;
db* db_reader(int flags);
db* db_writer(int flags);
void db_close(db* d);
st* st_new(db* d, int n);
void st_free(st* s);
")

c facade dep:
    resource Reader wraps *mut db
        from db_reader
        drop db_close
    resource Writer wraps *mut db
        from db_writer
        drop db_close
    resource Statement wraps *mut st
        from st_new
        drop st_free

fn main:
    print("x")
