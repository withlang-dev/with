//! expect-stdout: ok

// D51 §16.2b stage 2: a facade over imported declarations collects and
// verifies (§61) every fact it states; the program compiles and runs.
// (Stage 9 gave the callback clauses their meaning: a userdata is consumed
// by C or retained by the resource, not both, and `callback consumes` is
// refused until it is modeled — err_c_facade_userdata_consumed_and_retained,
// err_c_facade_callback_consumes_not_modeled.)

use c_import("typedef struct db db;\ntypedef struct st st;\n#define DB_OK 0\nint db_open(const char* path, db** out);\nvoid db_close(db* d);\ndb* db_dup(db* d);\nint db_prepare(db* d, const char* sql, st** out);\nvoid st_finalize(st* s);\ndb* st_db(st* s);\nint db_register(db* d, void* app, void (*destroy)(void*), int flags);\nint db_watch(db* d, int (*cb)(void*, int), void* app);\nint db_count(db* d);\n")

c facade dbl:
    domain errno thread
    resource Database wraps *mut db
        from db_open(out param 1)
        drop db_close
        destroys db_close
        ok DB_OK
        independent
        thread creator
    resource Statement wraps *mut st
        from db_prepare(out param out)
        drop st_finalize
        borrows param 0
    fn st_db
        returns borrow Database from param 0
        of Statement
        rename database
    fn db_register
        lend
        consumes param 1 destroyed_by param 2
        preserves param type i32
        preserves domain errno
        callback_thread any
    fn db_watch
        retains param cb by param d
        retains param app by param d
        callback param cb userdata param app
    fn db_close
        destroys

fn main:
    print("ok")
