//! expect-check-fail: matches 0 parameter(s)

// D51 §16.2b.13 / ruling §61: a facade statement that does not verify is an error.

use c_import("typedef struct db db;\ntypedef struct st st;\n#define DB_OK 0\nint db_open(const char* path, db** out);\nvoid db_close(db* d);\ndb* db_dup(db* d);\nint db_prepare(db* d, const char* sql, st** out);\nvoid st_finalize(st* s);\ndb* st_db(st* s);\nint db_register(db* d, void* app, void (*destroy)(void*), int flags);\nint db_count(db* d);\n")

c facade dbl:
    fn db_register
        preserves param type u64

fn main:
    print("ok")
