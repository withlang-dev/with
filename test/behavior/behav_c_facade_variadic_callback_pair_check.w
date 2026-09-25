//! check-only

// D66 retained variadic pairs (#1652, spec §16.2b.5, §16.2b.9): the shapes
// the pair-state flow accepts, over a declared (never linked) variadic
// setter: both halves set in either order with each status checked against
// the operation's `ok` constant; a reset between a callback-capable
// operation and a re-setup; a helper that receives the handle with a proven
// pair; a sink read between the setter and the run (D62: a capturing
// callable holds its places, and only a callback-capable operation calls
// it); and the handle destroyed — its Drop runs the abandonment path — on
// every early return, including one after a first successful setter.
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

fn run_twice(h: &Handle) -> c_int: h.run() + h.run()

fn callback_first() -> i32:
    var total = 0
    let sink = n => total = total + n
    var h = Handle.new().unwrap()
    if h.set(OPT_CB, on_n) != H_OK: return -1
    if h.set(OPT_UD, sink) != H_OK: return -1
    if h.set(OPT_N, 3) != H_OK: return -1
    let seen_before = total
    if h.run() != 0: return -1
    total - seen_before

fn userdata_first() -> i32:
    var total = 0
    let sink = n => total = total + n
    var h = Handle.new().unwrap()
    if h.set(OPT_UD, sink) != H_OK: return -1
    if h.set(OPT_CB, on_n) != H_OK: return -1
    if run_twice(h) != 0: return -1
    // The helper may have changed the pair: reset before running again.
    h.reset()
    if h.set(OPT_CB, on_n) != H_OK: return -1
    if h.set(OPT_UD, sink) != H_OK: return -1
    if h.run() != 0: return -1
    total

fn main:
    print(f"{callback_first() + userdata_first()}")
