//! expect-check-fail: a retained byte case states the option its length is set through, so the pointer and its length are one operation
//! expect-check-fail: = help: add 'length param CONST as T' after 'retains by param N', or state '&CString' when C reads the pointer as a NUL-terminated string

// #3129: bytes without a length are an overread.
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
            case OPT_DATA: &str retains by param 0

fn main:
    print("unreachable")
