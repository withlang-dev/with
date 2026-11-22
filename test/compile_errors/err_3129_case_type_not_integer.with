//! expect-check-fail: a case states an integer C type ('c_long', 'curl_off_t', an enum) or 'str'
//! expect-check-fail: = help: write 'case OPT_N: c_long' or 'case OPT_N: str'

// #3129 (§16.2b.5): the type a variadic case states.
use c_import("enum opt { OPT_URL = 1, OPT_N = 2 };\nstatic const double RATE = 1.5;\ntypedef struct h h;\nh *h_new(void);\nvoid h_free(h *x);\nint h_set(h *x, int which, ...);\nint h_setp(h *x, const char *which, ...);\n")

c contract hs:
    resource Handle wraps *mut h
        from h_new
        drop h_free
    fn h_set
        variadic param 2 selected by param which:
            case OPT_N: f64

fn main:
    print("unreachable")
