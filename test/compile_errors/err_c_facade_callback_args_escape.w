//! expect-check-fail: 'Arg' is a callback-scope handle, borrowed for the callback's invocation, and cannot outlive it

// Spec §16.2b.9 (D76, ruling Amendment 2): the argument vector a generated
// wrapper hands a callback is "valid for the callback's invocation only".
// Kept in global storage for use after the call returns, it would be a
// slice over pointers C has finished with; the slice and its handles are
// ephemeral, and the storage that would outlive the callback is refused.
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
        user_data from ctx_user_data as &U
    fn val_get
        of Arg

type Scale { k: i32 }

var KEPT: Option[&[Arg]] = None

fn step(t: Tally, args: &[Arg], s: &Scale):
    KEPT = Some(args)

fn main:
    let e = Engine.new().unwrap()
    print(f"{e.register(Scale { k: 2 }, step, null)}")
