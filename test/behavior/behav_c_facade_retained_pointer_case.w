//! check-only

// D194 (spec §16.2b.5 "Retained pointer cases", §16.2b.9 "Retained
// borrows"): the shapes the pair-state flow accepts for a retained pointer
// case, over a declared (never linked) variadic setter. A `&CString` bound
// before the handle is held until the handle dies; a case `until` lists
// releases the retention, after which the handle may be returned; a sized
// `&str` case sets its length option and pointer as one operation; the
// retention survives a run and a reset ends it.
use std.string.CString
use c_import("typedef struct h h;\nh *h_new(void);\nvoid h_free(h *x);\nvoid h_reset(h *x);\nint h_set(h *x, int opt, ...);\nint h_run(h *x);\n#define OPT_BODY 1\n#define OPT_CLEAR 2\n#define OPT_DATA 3\n#define OPT_SIZE 4\n#define OPT_N 5\n#define H_OK 0\n")

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
            case OPT_N: c_int
            case OPT_CLEAR: c_int
            case OPT_BODY: &CString retains by param 0 until OPT_CLEAR
            case OPT_DATA: &str retains by param 0 length param OPT_SIZE as c_long
    fn h_run
        rename run
        lend

fn body_outlives_handle():
    let body = "a=1&b=2".to_cstring().unwrap()
    let h = Req.new().unwrap()
    if h.set(OPT_BODY, body) != H_OK: return -1
    if h.run() != 0: return -1
    h.run()

fn released_then_returned():
    let body = "x".to_cstring().unwrap()
    let h = Req.new().unwrap()
    // OPT_CLEAR releases the body on its success edge; a failed clear or
    // set leaves the handle holding it, and the reset releases everything.
    // Each status is read in its own branch: a release pending on a status
    // read only through a compound condition stays pending, as a pair
    // setter's status does (§16.2b.9).
    if h.set(OPT_BODY, body) != H_OK: h.reset()
    else if h.set(OPT_CLEAR, 1) != H_OK: h.reset()
    h

fn reset_then_returned():
    let body = "x".to_cstring().unwrap()
    let h = Req.new().unwrap()
    // The handle holds the body whatever the setter's status; the reset
    // releases it, so the handle may leave the frame.
    h.set(OPT_BODY, body)
    h.reset()
    h

fn sized_bytes():
    let data = "raw\0bytes"
    let h = Req.new().unwrap()
    if h.set(OPT_DATA, data) != H_OK: return -1
    h.run()

fn main:
    let kept = released_then_returned()
    let fresh = reset_then_returned()
    print(f"{body_outlives_handle() + sized_bytes() + kept.run() + fresh.run()}")
