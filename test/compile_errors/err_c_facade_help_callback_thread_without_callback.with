//! expect-check-fail: fn 'util': 'callback_thread any' says the callback may run on any thread, but 'util' takes no callback
//! expect-check-fail: = help: delete 'callback_thread any'

// #3129: every contract refusal ends with the spelling that is accepted.
// 'callback_thread any' on a function that takes no callback.
use c_import("typedef struct db db;\ntypedef struct ctx ctx;\ndb* db_new(int f);\nvoid db_close(db* d);\nint util(int x);\nvoid ctx_end(ctx* c);\nconst char* db_name(int which);\nvoid db_undo(db* d, int x);\n")

c contract dbl:
    resource Database wraps *mut db
        from db_new
        drop db_close
    fn util
        callback_thread any

fn main: print(1)
