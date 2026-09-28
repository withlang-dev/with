//! expect-check-fail: ephemeral values cannot be stored in global storage

// Spec §16.2b.9 (D76, ruling Amendment 2): the registered user data a
// generated wrapper hands a callback is a borrow of the value the facade
// boxed, "valid for the callback's invocation only" — C may destroy the box
// once the call returns (a replaced registration, a closed connection).
// A '&U' kept in global storage is refused.
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

type Scale { k: i32 }

var KEPT: Option[&Scale] = None

fn step(t: Tally, args: &[Arg], s: &Scale):
    KEPT = Some(s)

fn main:
    let e = Engine.new().unwrap()
    print(f"{e.register(Scale { k: 2 }, step, null)}")
