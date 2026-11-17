//! expect-check-fail: a case states an integer C type ('c_long', 'curl_off_t', an enum) or 'str'
//! expect-check-fail: = help: write 'case OPT_DATA: c_long' or 'case OPT_DATA: str'; an out-pointer case has no form yet (#3119): present that call through a With function over the raw call

// #3129: a case's type is what C reads from the variadic slot.
use c_import("typedef struct h h;\nh *h_new(void);\nvoid h_free(h *x);\nint h_set(h *x, int opt, ...);\n#define OPT_DATA 1\n#define OPT_SIZE 2\n#define H_OK 0\n")

c contract lib:
    resource Handle wraps *mut h
        from h_new
        drop h_free
    fn h_set
        rename set
        lend
        ok H_OK
        variadic param 2 selected by param opt:
            case OPT_DATA: f64

fn main:
    print("unreachable")
