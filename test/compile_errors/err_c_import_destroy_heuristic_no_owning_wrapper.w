//! expect-error: raw c_import function call requires unsafe context

// #357 regression (BDFL ruling #16): a `*_destroy`/`*_free`/`*_close`/`*_unref`
// name heuristic may suggest a cleanup candidate but must NEVER, by itself,
// generate an owning wrapper or mark a raw C value as owned. A
// `widget_create`/`widget_destroy` pair therefore imports with a RAW surface:
// the constructor returns a raw `Widget *` and calling it requires `unsafe`.
//
// If the removed heuristic auto-owning-wrapper were active, `widget_create`
// would present as a safe owning constructor and this call would compile. It
// must not.

use c_import("typedef struct Widget Widget;\nWidget *widget_create(void);\nvoid widget_destroy(Widget *w);\n")

fn main:
    let w = widget_create()
    print("unreachable")
