//! expect-check-fail: fn 'ctx_free': 'destroys' is stated by the resource, not by the fn item

// Spec §16.2b.9 (ruling Amendment 1, #1611): "Nothing produces or destroys
// it" — an operation of a handle is a lend of it, never a destroyer. Since
// §31.8.2 no fn item says `destroys` at all: the resource owns that fact,
// and a handle is no resource.
use c_import("typedef struct ctx { int acc; } ctx;\nvoid ctx_free(ctx *c);\n")

c contract engines:
    handle Tally wraps *mut ctx
    fn ctx_free
        of Tally
        destroys

fn main:
    print("unreachable")
