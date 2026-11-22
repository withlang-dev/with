//! expect-check-fail: a variadic contract describes a lend or a free operation
//! expect-check-fail: = help: delete the 'variadic param …' clause, or remove the function from the resource's 'from', 'init', 'drop' and 'destroys' lines
//! expect-check-fail: is still a raw call after the facade covers its return
//! expect-check-fail: = help: add 'fn h_newv' with a clause for each pointer parameter ('text param N', 'buffer param P len param L', 'param N fixed null')

// #3129: a producer's arguments are its own; cases are stated on a lend or a free operation.
use c_import("typedef struct h h;\nh *h_newv(int opt, ...);\nvoid h_free(h *x);\n#define OPT_DATA 1\n")

c contract lib:
    resource Handle wraps *mut h
        from h_newv
        drop h_free
    fn h_newv
        variadic param 1 selected by param opt:
            case OPT_DATA: c_long

fn main:
    print("unreachable")
