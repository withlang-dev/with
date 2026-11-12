//! expect-check-fail: 'h_set' may invoke its callback from any thread ('callback_thread any' in facade hlib), so the userdata type must be Send and Sync

// §16.2b.10: `callback_thread any` on a function whose callback arrives
// through a variadic case speaks of that callback. The checker did not see
// it: the clause was refused as "takes no callback", and without it the
// userdata of the pair was never checked. A closure that writes a local is
// not shareable, so it cannot be the userdata of a callback any thread runs.
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
        callback_thread any
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

fn main:
    var total: i32 = 0
    let sink = n => total = total + n
    var h = Handle.new().unwrap()
    if h.set(OPT_CB, on_n) != H_OK: return 1
    if h.set(OPT_UD, sink) != H_OK: return 1
    if h.run() != 0: return 1
    print(f"{total}")
