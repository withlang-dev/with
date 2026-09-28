//! expect-check-fail: is presented through a wrapper the compiler generates, which reaches the program's callback through the registered user data

// Spec §16.2b.9 (D76, ruling Amendment 2): the argument vector is handed to
// the program's callback by a wrapper the compiler generates, and C calls
// that wrapper with no way to name which program callback it serves but the
// registration's user data. A vector with no 'user_data' clause has no
// wrapper that could reach the callback, and is refused rather than
// rendered as a raw call.
use c_import("typedef struct ctx ctx;\ntypedef struct val val;\ntypedef struct eng eng;\neng *eng_new(void);\nvoid eng_free(eng *e);\nint eng_register(eng *e, void *ud, void (*step)(ctx *, int, val **), void (*fin)(ctx *), void (*destroy)(void *));\nint eng_attach(eng *e, void *ud, void (*step)(ctx *, int, val **));\nvoid *ctx_user_data(ctx *c);\nint ctx_count(ctx *c);\nvoid ctx_add(ctx *c, int v);\nint val_get(val *v);\n")

c facade engines:
    resource Engine wraps *mut eng
        from eng_new
        drop eng_free
    handle Tally wraps *mut ctx
    handle Arg wraps *mut val
    fn eng_register
        consumes param ud destroyed_by param destroy
        retains param step by param 0
        retains param fin by param 0
        callback param step argv param 2 paired with argc param 1 as &[Arg]

fn main:
    let e = Engine.new().unwrap()
