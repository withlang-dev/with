//! expect-contract: contract-audit: profile fact shadowed: profile gobject.v1 rule unref (drop *_unref, profile:gobject.v1:unref@test/lib/gobject/v1.w:15) matched obj_unref for resource 'Object', and `drop` at test/contract/ok_profile_shadowed.w:18 states the fact explicitly; the facade's statement wins (§16.2b.2)
//! expect-contract: contract-audit: profile fact shadowed: profile gobject.v1 rule get (fn *_get* lend, profile:gobject.v1:get@test/lib/gobject/v1.w:17) matched 'obj_get_id', and the fn item at test/contract/ok_profile_shadowed.w:19 states the fact explicitly; the facade's statement wins (§16.2b.2)
//! expect-contract: violations=0 ok
//! expect-contract-not: ambiguous profile match

// D51 stage 11 (ruling §7.2, §63): explicit facade declarations override
// profile-derived facts. The resource states its own `drop obj_unref` and
// the facade describes `obj_get_id` itself, so the profile's `unref` and
// `get` rules are shadowed — reported as notes, not violations: the facade
// expressing its exception is the design, and the reader sees which of the
// profile's facts it replaced. `new` still applies (ok_profile_shadowed.expected).

use c_import("typedef struct obj obj;\nobj *obj_new(int id);\nvoid obj_unref(obj *o);\nint obj_get_id(obj *o);\n")

c facade objs:
    use convention gobject.v1
    resource Object wraps *mut obj
        drop obj_unref
    fn obj_get_id
        lend
        preserves param 0

fn main:
    print("ok")
