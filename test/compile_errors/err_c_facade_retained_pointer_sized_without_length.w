//! expect-check-fail: a retained byte case states the option its length is set through, so the pointer and its length are one operation

// D194 (spec §16.2b.5, §16.2b.8): `&[u8]` / `&str` in a retained case is
// bytes C reads to a length, and the case names the option that length is
// set through; without it the facade would present a pointer whose length
// safe code cannot state.
use c_import("typedef struct h h;\nh *h_new(void);\nvoid h_free(h *x);\nvoid h_reset(h *x);\nint h_set(h *x, int opt, ...);\n#define OPT_DATA 1\n#define H_OK 0\n")

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
        callbacks none
        ok H_OK
        variadic param 2 selected by param opt:
            case OPT_DATA: &str retains by param 0

fn main:
    let data = "bytes"
    let h = Handle.new().unwrap()
    print(f"{h.set(OPT_DATA, data)}")
