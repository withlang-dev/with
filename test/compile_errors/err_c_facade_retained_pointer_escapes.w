//! expect-check-fail: 'body' dies while 'Req' still holds it as the storage 'Req.set' set

// D194 (spec §16.2b.5, §16.2b.9): a handle holding a retained pointer
// borrow is ephemeral; returning it carries the borrow of the local
// `CString` past the frame, and the diagnostic names the storage that
// would die.
use std.string.CString
use c_import("typedef struct h h;\nh *h_new(void);\nvoid h_free(h *x);\nvoid h_reset(h *x);\nint h_set(h *x, int opt, ...);\nint h_run(h *x);\n#define OPT_BODY 1\n#define H_OK 0\n")

c contract hlib:
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
            case OPT_BODY: &CString retains by param 0
    fn h_run
        rename run
        lend

fn request() -> Req:
    let body = "a=1".to_cstring().unwrap()
    let h = Req.new().unwrap()
    if h.set(OPT_BODY, body) != H_OK: return h
    h

fn main:
    let h = request()
    print(f"{h.run()}")
