//! expect-check-fail: 'until h_other' names neither a case of this variadic operation nor a modeled operation of 'Req'

// D194 (spec §16.2b.5): each name after `until` is a case of the same
// variadic operation or a modeled operation of the retaining resource; a
// release is never inferred from a name the facade does not describe.
use std.string.CString
use c_import("typedef struct h h;\nh *h_new(void);\nvoid h_free(h *x);\nvoid h_reset(h *x);\nint h_set(h *x, int opt, ...);\nint h_other(h *x);\n#define OPT_BODY 1\n#define H_OK 0\n")

c facade hlib:
    resource Req wraps *mut h
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
            case OPT_BODY: &CString retains by param 0 until h_other

fn main:
    let body = "a=1".to_cstring().unwrap()
    let h = Req.new().unwrap()
    print(f"{h.set(OPT_BODY, body)}")
