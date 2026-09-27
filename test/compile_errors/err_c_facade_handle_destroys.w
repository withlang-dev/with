//! expect-check-fail: fn 'ctx_free' is an operation of the callback-scope handle 'Tally' and states 'destroys'

// Spec §16.2b.9 (ruling Amendment 1, #1611): "Nothing produces or destroys
// it" — an operation of a handle is a lend of it, never a destroyer.
use c_import("typedef struct ctx { int acc; } ctx;\nvoid ctx_free(ctx *c);\n")

c facade engines:
    handle Tally wraps *mut ctx
    fn ctx_free
        of Tally
        destroys

fn main:
    print("unreachable")
