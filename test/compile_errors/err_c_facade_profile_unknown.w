//! expect-check-fail: import module not found: 'nosuch.v1'

// D51 stage 11 (§16.2b.12): `use convention` resolves the profile through
// ordinary package rules; a package that does not exist is the unresolved
// import, naming it.

use c_import("typedef struct obj obj;\nobj *obj_new(int id);\nvoid obj_unref(obj *o);\n")

c facade objs:
    use convention nosuch.v1
    resource Object wraps *mut obj

fn main:
    print("ok")
