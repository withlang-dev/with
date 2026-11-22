//! expect-check-fail: a variadic contract describes a lend (with fixed arguments at most)
//! expect-check-fail: = help: keep the 'variadic param …' clause and 'param N fixed …'; delete the other clauses of this item

// #3129 (§16.2b.5): a variadic contract is a lend.
use c_import("enum opt { OPT_URL = 1, OPT_N = 2 };\nstatic const double RATE = 1.5;\ntypedef struct h h;\nh *h_new(void);\nvoid h_free(h *x);\nint h_set(h *x, int which, ...);\nint h_setp(h *x, const char *which, ...);\n")

c contract hs:
    resource Handle wraps *mut h
        from h_new
        drop h_free
    fn h_set
        consumes param 0
        variadic param 2 selected by param which:
            case OPT_N: c_long

fn main:
    print("unreachable")
