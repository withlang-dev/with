//! expect-check-fail: a retained case's length option names an imported selector constant, not a parameter index (§16.2b.5)
//! expect-check-fail: = help: after 'length param' write the option constant that sets the length (CURLOPT_POSTFIELDSIZE_LARGE)

// #3129 (§16.2b.5): the length is set through an option, and an option is a constant of the header.
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
            case OPT_DATA: &str retains by param 0 length param 1 as c_long

fn main:
    print("unreachable")
