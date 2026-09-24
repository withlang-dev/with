//! expect-contract: violations=0 ok
//! expect-contract-not: ambiguous profile match
//! expect-contract-not: profile fact shadowed

// D51 stage 11 (ruling §7, §59, §63; spec §16.2b.12): a facade that states
// only its resource and adopts `gobject.v1` (test/lib/gobject/v1.w). The
// contract view shows every profile-derived fact with the provenance
// `profile:gobject.v1:<rule>@<file>:<line>` (ok_profile_applied.expected):
// `obj_new` produced by rule `new`, `obj_unref` the automatic destroyer by
// rule `unref`, `obj_free` an alternate destroyer by rule `free`,
// `obj_get_id` a lend by rule `get`.

use c_import("typedef struct obj obj;\nobj *obj_new(int id);\nvoid obj_unref(obj *o);\nvoid obj_free(obj *o, int flags);\nint obj_get_id(obj *o);\n")

c facade objs:
    use convention gobject.v1
    resource Object wraps *mut obj

fn main:
    print("ok")
