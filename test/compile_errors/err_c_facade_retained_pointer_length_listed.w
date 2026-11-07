//! expect-check-fail: 'case OPT_DATA' sets its length through OPT_SIZE, so OPT_SIZE is not listed as a case of its own

// D194 (spec §16.2b.5; D51 §9): a sized retained case's length option is
// set only through the case's own operation. Listing it as a case too would
// let safe code set a pointer and a length apart — the overread the pairing
// exists to close.
use c_import("typedef struct h h;\nh *h_new(void);\nvoid h_free(h *x);\nvoid h_reset(h *x);\nint h_set(h *x, int opt, ...);\n#define OPT_DATA 1\n#define OPT_SIZE 2\n#define H_OK 0\n")

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
            case OPT_SIZE: c_long
            case OPT_DATA: &str retains by param 0 length param OPT_SIZE as c_long

fn main:
    let data = "bytes"
    let h = Handle.new().unwrap()
    print(f"{h.set(OPT_DATA, data)}")
