//! expect-check-fail: an absent callback takes its userdata with it
//! expect-check-fail: = help: delete the 'nullable' clause; pass `null` at a raw call when C allows it

// #3129 (§16.2b.9): nullability is rendered for a function pointer, a paired callback and a const char *; a bare void * has no Option form.
use c_import("typedef struct ctx ctx;\ntypedef struct val val;\ntypedef struct eng eng;\neng *eng_new(void);\nvoid eng_free(eng *e);\nint eng_register(eng *e, void *ud, void (*step)(ctx *, int, val **), void (*fin)(ctx *), void (*destroy)(void *));\nint eng_twice(eng *e, void *ud, void (*step)(ctx *, ctx *, int, val **), void (*destroy)(void *));\nint eng_bare(eng *e, void *ud, void (*step)(int, val **), void (*destroy)(void *));\nvoid *ctx_user_data(ctx *c);\nint val_get(val *v);\nconst char *eng_msg(int code);\neng *eng_child(int a, int b);\nvoid eng_opt(eng *e, void *ud);\n")

c contract engines:
    resource Engine wraps *mut eng
        from eng_new
        drop eng_free
    handle Tally wraps *mut ctx
    handle Arg wraps *mut val
    fn eng_opt
        lend
        nullable param ud

fn main:
    print("unreachable")
