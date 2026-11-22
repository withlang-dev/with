//! expect-check-fail: a variadic callback's userdata selector names no imported integer constant (§16.2b.5)
//! expect-check-fail: = help: after 'userdata param' write the option constant as the header names it (CURLOPT_WRITEDATA)

// #3129 (§16.2b.5): the userdata option is a constant the header declares.
use c_import("typedef struct h h;\ntypedef int (*h_cb)(char *p, unsigned long n, void *ud);\nh *h_new(void);\nvoid h_free(h *x);\nvoid h_reset(h *x);\nint h_set(h *x, int opt, ...);\n#define OPT_DATA 1\n#define OPT_SIZE 2\n#define OPT_CB 3\n#define OPT_UD 4\n#define H_OK 0\n")

c contract hlib:
    resource Handle wraps *mut h
        from h_new
        drop h_free
        abandon h_reset
    fn h_reset
        rename reset
        lend
        callbacks none
    fn h_set
        rename set
        lend
        ok H_OK
        variadic param 2 selected by param opt:
            case OPT_CB: callback param 2 as h_cb userdata param OPT_NOPE retains by param 0

fn main:
    print("unreachable")
