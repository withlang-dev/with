//! expect-check-fail: installs a callback the library keeps for later calls; state its retention
//! expect-check-fail: = help: write 'case OPT_CB: callback param N as T userdata param CONST retains by param 0'

// #3129 (§16.2b.5, §16.2b.9): an option that installs a callback is kept by
// the library; the case says which resource keeps it.
use c_import("typedef struct h h;\nh *h_new(void);\nvoid h_free(h *x);\nint h_set(h *x, int opt, ...);\nenum other { OTHER_A = 1 };\ntypedef enum kind { K_A = 1, K_B = 2 } kind;\ntypedef struct rec { kind k; } rec;\nint fill(rec *out);\nint put(int a, int b);\n#define OPT_CB 3\n#define OPT_UD 4\n#define OPT_F 1.5\n#define H_OK 0\ntypedef int (*h_cb)(void *ud);\n")

c contract lib:
    resource Handle wraps *mut h
        from h_new
        drop h_free
    fn h_set
        rename set
        lend
        ok H_OK
        variadic param 2 selected by param opt:
            case OPT_CB: callback param 2 as h_cb userdata param OPT_UD

fn main:
    print("unreachable")
