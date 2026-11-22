//! expect-check-fail: which is not an integer or enum; the selector is the parameter whose compile-time value picks the case
//! expect-check-fail: = help: after 'selected by' name the integer or enum parameter the header's option constants are passed in

// #3129 (§16.2b.5): the selector of a variadic contract.
use c_import("enum opt { OPT_URL = 1, OPT_N = 2 };\nstatic const double RATE = 1.5;\ntypedef struct h h;\nh *h_new(void);\nvoid h_free(h *x);\nint h_set(h *x, int which, ...);\nint h_setp(h *x, const char *which, ...);\n")

c contract hs:
    resource Handle wraps *mut h
        from h_new
        drop h_free
    fn h_setp
        variadic param 2 selected by param which:
            case OPT_N: c_long

fn main:
    print("unreachable")
