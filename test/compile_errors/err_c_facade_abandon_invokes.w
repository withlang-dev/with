//! expect-check-fail: resource 'Handle': 'abandon h_run' names an operation that may invoke callbacks, so it cannot safely abandon an incomplete callback pair

// D66 (spec §16.2b.9): the abandonment path must itself be `callbacks
// none`, or abandoning a half-configured pair could invoke it.
use c_import("typedef struct h h;\nh *h_new(void);\nvoid h_free(h *x);\nvoid h_reset(h *x);\nint h_set(h *x, int opt, ...);\nint h_run(h *x);\ntypedef int (*h_cb)(int n, void *ud);\n#define OPT_CB 1\n#define OPT_UD 2\n#define OPT_N 3\n#define H_OK 0\n")

c facade hlib:
    resource Handle wraps *mut h
        from h_new
        drop h_free
        abandon h_run
    fn h_run
        rename run
        lend

fn main:
    print("unreached")
