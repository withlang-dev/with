//! expect-stdout: ok

// D51 §16.2b stage 1: every item and clause form of the specification parses
// (over declared functions, since stage 2 verifies every reference).

use c_import("typedef struct db db;\ntypedef struct st st;\n#define DB_OK 0\nint db_open(const char* path, db** out);\nvoid db_close(db* d);\ndb* db_dup(db* d);\nint db_prepare(db* d, const char* sql, st** out);\nvoid st_finalize(st* s);\ndb* st_db(st* s);\nint db_register(db* d, void* app, void (*destroy)(void*), int flags);\nint db_count(db* d);\n")

c facade dbl:
    resource Database wraps *mut db
        from db_open(out param 1)
        drop db_close
        destroys db_close
        ok DB_OK
        independent
        thread creator
    resource Statement wraps *mut st
        from db_prepare(out param 2)
        drop st_finalize
        borrows param 0
    fn st_db
        returns borrow Database from param 0
        of Statement
        rename database
    fn db_register
        lend
        consumes param 1 destroyed_by param 2
        retains param 1 by param 0
        preserves param 0
        preserves domain environ
        callback consumes param 1
        callback_thread any
    fn db_close
        destroys
    domain errno thread
    domain environ process
    use convention gobject.v1

fn main:
    print("ok")
