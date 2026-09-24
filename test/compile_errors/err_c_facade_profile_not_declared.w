//! expect-check-fail: use convention noprofile.v1: module 'noprofile.v1' declares no convention profile 'noprofile.v1' (§16.2b.12)

// D51 stage 11 (§16.2b.12): the package resolved (test/lib/noprofile/v1.w)
// but declares no `c convention noprofile.v1:` block — an error naming the
// package, never a silent adoption of nothing.

use c_import("typedef struct obj obj;\nobj *obj_new(int id);\nvoid obj_unref(obj *o);\n")

c facade objs:
    use convention noprofile.v1
    resource Object wraps *mut obj

fn main:
    print("ok")
