//! expect-check-fail: whose parameters C does not name; refer to it by position
//! expect-check-fail: = help: write 'argv param N', with N the callback parameter's position counted from zero

// #3129 (§16.2b.9): a function-pointer type names no parameters; a clause counts them.
use c_import("typedef struct ctx ctx;\ntypedef struct val val;\ntypedef struct eng eng;\neng *eng_new(void);\nvoid eng_free(eng *e);\nint eng_register(eng *e, void *ud, void (*step)(ctx *, int, val **), void (*fin)(ctx *), void (*destroy)(void *));\nint eng_twice(eng *e, void *ud, void (*step)(ctx *, ctx *, int, val **), void (*destroy)(void *));\nint eng_bare(eng *e, void *ud, void (*step)(int, val **), void (*destroy)(void *));\nvoid *ctx_user_data(ctx *c);\nint val_get(val *v);\nconst char *eng_msg(int code);\neng *eng_child(int a, int b);\nvoid eng_opt(eng *e, void *ud);\n")

c contract engines:
    resource Engine wraps *mut eng
        from eng_new
        drop eng_free
    handle Tally wraps *mut ctx
    handle Arg wraps *mut val
    fn eng_register
        consumes param ud destroyed_by param destroy
        retains param step by param 0
        retains param fin by param 0
        callback param step argv param argv paired with argc param argc as &[Arg]
        user_data from ctx_user_data as &U

fn main:
    print("unreachable")
