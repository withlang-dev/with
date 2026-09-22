//! expect-check-fail: does not take the consumed param 1

// D51 §16.2b.9 / ruling §61: the callable a `destroyed_by` names takes the
// consumed parameter first, under the destroyer rule (exact type, or a
// `void *` for an object pointer). `void (*)(int)` does not take `void *app`.

use c_import("typedef struct db db;\nint db_register(db* d, void* app, void (*destroy)(int), int flags);\n")

c facade dbl:
    fn db_register
        consumes param 1 destroyed_by param 2

fn main:
    print("ok")
