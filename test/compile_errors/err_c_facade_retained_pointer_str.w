//! expect-check-fail: a retained pointer case keeps the caller's storage past the call, and a 'str' is copied to a C string that dies at the return

// D194 (spec §16.2b.5, §16.3c): a `str` by value in a retained case is a
// call-scoped C string; the refusal names the owned form to bind instead.
use c_import("typedef struct h h;\nh *h_new(void);\nvoid h_free(h *x);\nvoid h_reset(h *x);\nint h_set(h *x, int opt, ...);\n#define OPT_BODY 1\n#define H_OK 0\n")

c facade hlib:
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
        callbacks none
        ok H_OK
        variadic param 2 selected by param opt:
            case OPT_BODY: str retains by param 0

fn main:
    let h = Handle.new().unwrap()
    print(f"{h.set(OPT_BODY, "a=1")}")
