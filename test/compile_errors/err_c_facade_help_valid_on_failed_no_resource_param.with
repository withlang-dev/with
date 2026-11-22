//! expect-check-fail: fn 'util': 'valid on failed' marks an operation of the failed state of the resource its first parameter receives
//! expect-check-fail: = help: delete 'valid on failed', or make the failed resource the function's first parameter

// #3129: every contract refusal ends with the spelling that is accepted.
// 'valid on failed' on a function whose first parameter receives no resource.
use c_import("typedef struct db db;\ntypedef struct ctx ctx;\ndb* db_new(int f);\nvoid db_close(db* d);\nint util(int x);\nvoid ctx_end(ctx* c);\nconst char* db_name(int which);\nvoid db_undo(db* d, int x);\n")

c contract dbl:
    resource Database wraps *mut db
        from db_new
        drop db_close
    fn util
        valid on failed

fn main: print(1)
