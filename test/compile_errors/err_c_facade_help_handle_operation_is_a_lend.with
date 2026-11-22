//! expect-check-fail: fn 'ctx_end' is an operation of the callback-scope handle 'Tally' and states 'consumes'
//! expect-check-fail: = help: delete that clause: an operation of a callback-scope handle is a lend

// #3129: every contract refusal ends with the spelling that is accepted.
// A handle's operation that states more than a lend.
use c_import("typedef struct db db;\ntypedef struct ctx ctx;\ndb* db_new(int f);\nvoid db_close(db* d);\nint util(int x);\nvoid ctx_end(ctx* c);\nconst char* db_name(int which);\nvoid db_undo(db* d, int x);\n")

c contract dbl:
    resource Database wraps *mut db
        from db_new
        drop db_close
    handle Tally wraps *mut ctx
    fn ctx_end
        of Tally
        consumes param 0

fn main: print(1)
