//! expect-check-fail: cannot read `total` while `sink` is a live mutating view into it

// D66 (spec §16.2b.9 "Retained borrows"): the userdata a setter installs
// is held by the handle until its last callback-capable operation, so the
// sink's captured place cannot be read between the setter and the run —
// the retention keeps the mutating view alive (§12.4, #1691).
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
            case OPT_CB: callback param 2 as h_cb userdata param OPT_UD retains by param 0
    fn h_run
        rename run
        lend

fn on_n(n: c_int, sink: &fn(i32) -> Unit) -> c_int:
    sink(n)
    0

fn main:
    var total = 0
    let sink = n => total = total + n
    var h = Handle.new().unwrap()
    if h.set(OPT_CB, on_n) != H_OK: return 1
    if h.set(OPT_UD, sink) != H_OK: return 1
    let before = total
    if h.run() != 0: return 1
    print(f"{total - before}")
