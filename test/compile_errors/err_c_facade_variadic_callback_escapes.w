//! expect-check-fail: 'Handle' holds a retained callback borrow and cannot be returned or stored; it is ephemeral until reset or destroyed

// D66 (spec §16.2b.9 "Retained borrows"): a resource holding a retained
// borrow is ephemeral for that window — returning it would carry the
// borrow of a local past the frame.
use c_import("typedef struct h h;\nh *h_new(void);\nvoid h_free(h *x);\nvoid h_reset(h *x);\nint h_set(h *x, int opt, ...);\nint h_run(h *x);\ntypedef int (*h_cb)(int n, void *ud);\n#define OPT_CB 1\n#define OPT_UD 2\n#define OPT_N 3\n#define H_OK 0\n")

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
            case OPT_N: c_int
            case OPT_CB: callback param 2 as h_cb userdata param OPT_UD retains by param 0
    fn h_run
        rename run
        lend

fn on_n(n: c_int, sink: &fn(i32) -> Unit) -> c_int:
    sink(n)
    0

fn configured() -> Handle:
    var total = 0
    let sink = n => total = total + n
    var h = Handle.new().unwrap()
    if h.set(OPT_CB, on_n) == H_OK and h.set(OPT_UD, sink) == H_OK: h else: h

fn main:
    let h = configured()
    print(f"{h.run()}")
