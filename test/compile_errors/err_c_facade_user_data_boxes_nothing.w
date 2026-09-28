//! expect-check-fail: presents the value the facade boxed, and 'eng_attach' boxes none

// Spec §16.2b.9 (D76, ruling Amendment 2): 'user_data as &U' presents "the
// value the facade boxed". A registration whose 'void *' is neither
// consumed with its destroy callback nor retained by the resource hands C
// no box — the accessor would return a pointer With never gave it, read as
// '&U'.
use c_import("typedef struct ctx ctx;\ntypedef struct val val;\ntypedef struct eng eng;\neng *eng_new(void);\nvoid eng_free(eng *e);\nint eng_register(eng *e, void *ud, void (*step)(ctx *, int, val **), void (*fin)(ctx *), void (*destroy)(void *));\nint eng_attach(eng *e, void *ud, void (*step)(ctx *, int, val **));\nvoid *ctx_user_data(ctx *c);\nint ctx_count(ctx *c);\nvoid ctx_add(ctx *c, int v);\nint val_get(val *v);\n")

c facade engines:
    resource Engine wraps *mut eng
        from eng_new
        drop eng_free
    handle Tally wraps *mut ctx
    handle Arg wraps *mut val
    fn eng_attach
        retains param step by param 0
        callback param step argv param 2 paired with argc param 1 as &[Arg]
        user_data from ctx_user_data as &U

fn main:
    let e = Engine.new().unwrap()
