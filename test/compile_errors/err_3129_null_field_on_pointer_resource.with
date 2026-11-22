//! expect-check-fail: names a field of a record passed by value
//! expect-check-fail: = help: write 'from h_new, nonnull': the returned pointer is the one that may be NULL

// #3129: a pointer resource's NULL is the pointer itself.
use c_import("typedef struct h h;\nh *h_new(void);\nvoid h_free(h *x);\nint h_set(h *x, int opt, ...);\n#define OPT_DATA 1\n#define OPT_SIZE 2\n#define H_OK 0\n")

c contract lib:
    resource Handle wraps *mut h
        from h_new, nonnull field x
        drop h_free

fn main:
    print("unreachable")
