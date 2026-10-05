//! expect-check-fail: fn 'db_run' is described twice in this facade
//! expect-check-fail: give each item its own 'rename'

// D92 (ruling Amendment 3, §16.2b.11): one C function is presented as two
// operations only under two distinct renames. Two items sharing a rename,
// or one of them stating none, describe the same operation twice.
use c_import("typedef struct db db;\n#define DB_OK 0\ndb* db_new(void);\nvoid db_close(db* d);\nint db_run(db* d, int code);\n")

c facade dbl:
    resource Database wraps *mut db
        from db_new
        drop db_close
    fn db_run
        rename run
        ok DB_OK
    fn db_run
        param code fixed 0
        ok DB_OK

fn main:
    print("unreachable")
