//! expect-check-fail: fn 'h_set': 'case OPT_CB' installs a callback the library keeps for later calls; state its retention

// D66 (spec §16.2b.5, §16.2b.9): retention is stated, never inferred — a
// callback case without `retains by param N` is refused rather than
// modeled as kept.
use c_import("typedef struct h h;\nh *h_new(void);\nvoid h_free(h *x);\nvoid h_reset(h *x);\nint h_set(h *x, int opt, ...);\nint h_run(h *x);\ntypedef int (*h_cb)(int n, void *ud);\n#define OPT_CB 1\n#define OPT_UD 2\n#define OPT_N 3\n#define H_OK 0\n")

c facade hlib:
    resource Handle wraps *mut h
        from h_new
        drop h_free
    fn h_set
        rename set
        lend
        callbacks none
        ok H_OK
        variadic param 2 selected by param opt:
            case OPT_CB: callback param 2 as h_cb userdata param OPT_UD

fn main:
    print("unreached")
