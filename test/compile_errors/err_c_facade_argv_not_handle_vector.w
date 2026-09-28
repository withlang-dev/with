//! expect-check-fail: argv param 1 of the callback param 2: extern "C" fn(*mut ctx, i32, *mut *mut val) -> Unit step is i32; an argument vector is a pointer to the handles C passes

// Spec §16.2b.9 (D76, ruling Amendment 2): the pairing is stated, and
// checked against the callback's C type — the vector is the 'T **' C passes
// beside its count, never the count itself. The positions are the
// callback's own parameters, counted from zero (here swapped).
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
        callback param step argv param 1 paired with argc param 2 as &[Arg]
        user_data from ctx_user_data as &U

fn main:
    let e = Engine.new().unwrap()
