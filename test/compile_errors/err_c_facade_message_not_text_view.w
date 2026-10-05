//! expect-check-fail: 'message db_count' names an operation that is not a text view of its first parameter

// D92 (ruling Amendment 3, §16.2b.4): `message` names the operation that
// describes the resource's most recent failure, and the error carries its
// text: it is a text view of the resource, stated as one.
use c_import("typedef struct db db;\n#define DB_OK 0\ndb* db_new(void);\nvoid db_close(db* d);\nint db_run(db* d, int code);\nint db_count(db* d);\n")

c facade dbl:
    resource Database wraps *mut db
        from db_new
        drop db_close
        message db_count
    fn db_count
        lend
    fn db_run
        ok DB_OK

fn main:
    print("unreachable")
