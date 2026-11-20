//! expect-check-fail: resource 'Database': 'abandon db_undo' takes 2 parameters; the abandonment path takes only the representation
//! expect-check-fail: = help: after 'abandon' name a function that takes the wrapped pointer and nothing else

// #3129: every contract refusal ends with the spelling that is accepted.
// An `abandon` function with a second parameter.
use c_import("typedef struct db db;\ndb* db_new(int f);\nvoid db_close(db* d);\nvoid db_undo(db* d, int x);\n")

c contract dbl:
    resource Database wraps *mut db
        from db_new
        drop db_close
        abandon db_undo

fn main: print(1)
