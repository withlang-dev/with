//! expect-contract: contract-audit: resources=3 items=2 domains=0 conventions=0 advisories=0 profile-ambiguous=0 profile-shadowed=0
//! expect-contract: violations=0 ok

// D76 (ruling Amendment 2, spec §16.2b.9, §63): the foreign-contract view
// reports what a generated wrapper hands a registered callback — its
// argument vector as a slice of a callback-scope handle, and the user data
// the facade boxed as `&U`, read back through the accessor the facade
// names — each with the clause that stated it (ok_callback_arguments.expected).

use c_import("typedef struct ctx ctx;\ntypedef struct val val;\ntypedef struct eng eng;\neng *eng_new(void);\nvoid eng_free(eng *e);\nint eng_register(eng *e, void *ud, void (*step)(ctx *, int, val **), void (*fin)(ctx *), void (*destroy)(void *));\nvoid *ctx_user_data(ctx *c);\nint val_get(val *v);\n")

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

fn main:
    let e = Engine.new().unwrap()
