//! expect-check-fail: fn 'db_name': 'returns static CStr' is presented under the C name at its call sites
//! expect-check-fail: = help: delete the 'rename' line: the function is called by its C name

// #3129: every contract refusal ends with the spelling that is accepted.
// 'rename' on a function presented under its C name.
use c_import("typedef struct db db;\ntypedef struct ctx ctx;\ndb* db_new(int f);\nvoid db_close(db* d);\nint util(int x);\nvoid ctx_end(ctx* c);\nconst char* db_name(int which);\nvoid db_undo(db* d, int x);\n")

c contract dbl:
    resource Database wraps *mut db
        from db_new
        drop db_close
    fn db_name
        returns static CStr
        rename name

fn main: print(1)
