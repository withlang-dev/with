//! expect-stdout: resets 1 closes 1

// #3177 (§31): `abandon f(param N)` names the parameter that receives the
// resource, the first when the parentheses are absent; every other
// parameter is fixed or discarded on the function's own item, as for
// `drop` (D209). The abandonment path runs before the destroyer.
use c_import("typedef struct h { int open; } h;
static h the_h;
static int resets;
static int closes;
static inline h *h_open(void) { the_h.open = 1; return &the_h; }
static inline void h_reset(int *err, h *p) { *err = 0; resets++; }
static inline void h_close(h *p) { p->open = 0; closes++; }
static inline int h_resets(void) { return resets; }
static inline int h_closes(void) { return closes; }
")

c contract hs:
    resource Handle wraps *mut h
        from h_open
        drop h_close
        abandon h_reset(param 1)
    fn h_reset
        param 0 discarded
        callbacks none

fn main:
    if true:
        let _h = Handle.open().unwrap()
    print(f"resets {h_resets()} closes {h_closes()}")
