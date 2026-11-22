//! expect-check-fail: names a global that does not hold a function of one parameter taking the pointer the resource wraps
//! expect-check-fail: = help: after 'drop' name an imported function, or a global function pointer, that takes the wrapped pointer and nothing else

// #3129 (§31.8.6): a destroyer is a function, or a global that holds one.
use c_import("typedef struct h h;\nh *h_new(void);\nint h_count;\n")

c contract lib:
    resource Handle wraps *mut h
        from h_new
        drop h_count

fn main:
    print("unreachable")
