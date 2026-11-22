//! expect-check-fail: retention by another parameter is not modeled
//! expect-check-fail: = help: write 'retains param N by param 0': the keeper is the resource the operation is a method of

// #3129 (§16.2b.9): a retained callback is kept by the operation's own resource.
use c_import("typedef struct db db;\ntypedef int (*db_cb)(void *ud, int n);\ntypedef void (*db_dtor)(void *ud);\ndb *db_new(void);\nvoid db_close(db *d);\nint db_pair(db *a, db *b, db_cb cb, void *ud);\nint db_adopt(db *a, db *b, db_dtor d);\n")

c contract dbc:
    resource Database wraps *mut db
        from db_new
        drop db_close
    fn db_pair
        callback param 2 userdata param 3
        retains param 2 by param 1

fn main:
    print("unreachable")
