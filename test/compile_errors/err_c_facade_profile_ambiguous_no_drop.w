//! expect-check-fail: use convention gobject.v1: rule unref (drop *_unref) matches 2 candidates for resource 'Object': obj_unref, obj_later_unref; a profile fact must resolve uniquely, so the rule contributes nothing (§16.2b.12) — state 'drop <fn>' on the resource to choose
//! expect-check-fail: resource 'Object': producer 'obj_new' with no 'drop' and no 'destroys' — never half-model unsafely

// D51 stage 11 (ruling §7.1, §9): an ambiguous profile match contributes
// nothing, and the resource it would have completed is then half-modeled:
// the production the profile supplied has no destroy path, which Sema
// refuses as it refuses any such resource. The warning names the profile,
// the rule, the item, the candidates and the clause that resolves it.

use c_import("typedef struct obj obj;\nobj *obj_new(int id);\nvoid obj_unref(obj *o);\nvoid obj_later_unref(obj *o);\n")

c facade objs:
    use convention gobject.v1
    resource Object wraps *mut obj

fn main:
    print("ok")
