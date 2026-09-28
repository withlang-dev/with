//! expect-check-fail: an ephemeral value cannot be stored on the heap

// Spec §16.2b.9 (D76), §5.1: the user data a registration consumes moves
// into a box C keeps past the call, and the callbacks read it as '&U' for
// as long as C keeps it. A value borrowing a local would be read after the
// local died, so an ephemeral value is refused as the box's content, as
// 'Box.new' of one is — here through the tuple the box carries the
// program's callbacks in.
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

type Keep = ephemeral { r: &i32 }

fn step(t: Tally, args: &[Arg], k: &Keep):
    print(f"{*k.r}")

fn register(e: &Engine):
    let local = 5
    print(f"{e.register(Keep { r: &local }, step, null)}")

fn main:
    let e = Engine.new().unwrap()
    register(e)
