//! expect-check-fail: raw c_import function call requires unsafe context: `box_name` is an operation of `Crate`; write `value.name(…)`

// §31.4: a described function has the meaning its contract gives it.
// `box_name` returns a view borrowed from the `Crate` it is given: that is
// the method on the resource. By its C name it takes the raw pointer, and
// the call is raw; the error names the presented spelling.
use c_import("typedef struct box box;
box *box_new(int n);
void box_free(box *b);
const char *box_name(box *b);
")

c contract boxes:
    resource Crate wraps *mut box
        from box_new
        drop box_free
    fn box_name
        returns borrow CStr from param 0
        preserves param 0

fn main:
    let p: *mut box = null
    let n = box_name(p)
