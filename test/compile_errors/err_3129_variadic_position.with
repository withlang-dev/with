//! expect-check-fail: but the variadic position of 'h_set' is param 2
//! expect-check-fail: = help: write 'variadic param 2 selected by param P:', with P the parameter whose constant picks the case

// #3129 (§16.2b.5): the variadic position is the parameter count.
use c_import("enum opt { OPT_URL = 1, OPT_N = 2 };\nstatic const double RATE = 1.5;\ntypedef struct h h;\nh *h_new(void);\nvoid h_free(h *x);\nint h_set(h *x, int which, ...);\nint h_setp(h *x, const char *which, ...);\n")

c contract hs:
    resource Handle wraps *mut h
        from h_new
        drop h_free
    fn h_set
        variadic param 1 selected by param which:
            case OPT_N: c_long

fn main:
    print("unreachable")
