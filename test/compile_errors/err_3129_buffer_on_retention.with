//! expect-check-fail: a slice in that rendering is not modeled
//! expect-check-fail: = help: delete the buffer clause; the function keeps its raw pointer and length parameters

// #3129 (§16.2b.8): a retention contract keeps the pointer past the call; a slice is a view for the call.
use c_import("typedef struct h h;\nh *h_new(void);\nvoid h_free(h *x);\nint h_take(h *x, const char *p, unsigned long n);\n")

c contract lib:
    resource Handle wraps *mut h
        from h_new
        drop h_free
    fn h_take
        lend
        buffer param p len param n
        retains param p by param 0

fn main:
    print("unreachable")
