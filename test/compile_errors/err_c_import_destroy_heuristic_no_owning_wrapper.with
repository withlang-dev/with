//! expect-error: raw c_import function call requires unsafe context

// #357 regression (BDFL ruling #16): a `*_destroy`/`*_free`/`*_close`/`*_unref`
// name heuristic may suggest a cleanup candidate but must NEVER, by itself,
// generate an owning wrapper or mark a raw C value as owned. A
// `widget_create`/`widget_destroy` pair therefore imports with a RAW surface:
// the constructor returns a raw `Widget *` (inert, §31.4), and handing it to
// `widget_destroy` requires `unsafe`.
//
// If the removed heuristic auto-owning-wrapper were active, the pair would
// present as a safe owning type and this would compile. It must not.

use c_import("typedef struct Widget Widget;\nWidget *widget_create(void);\nvoid widget_destroy(Widget *w);\n")

fn main:
    let w = widget_create()
    widget_destroy(w)
    print("unreachable")
