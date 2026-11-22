//! expect-check-fail: a destroy callback destroys userdata (a 'void *' no resource wraps)
//! expect-check-fail: = help: for a resource write 'consumes param N' alone; its own 'drop' or 'destroys' operation destroys it

// #3129 (§16.2b.5, §16.2b.9): a destroy callback is for userdata.
use c_import("typedef struct db db;\ntypedef int (*db_cb)(void *ud, int n);\ntypedef void (*db_dtor)(void *ud);\ndb *db_new(void);\nvoid db_close(db *d);\nint db_pair(db *a, db *b, db_cb cb, void *ud);\nint db_adopt(db *a, db *b, db_dtor d);\n")

c contract dbc:
    resource Database wraps *mut db
        from db_new
        drop db_close
    fn db_adopt
        consumes param 1 destroyed_by param 2

fn main:
    print("unreachable")
