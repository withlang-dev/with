//! expect-contract: contract: ambiguous profile match: profile gobject.v1 rule unref (drop *_unref, profile:gobject.v1:unref@test/lib/gobject/v1.w:15) matches 2 candidates for resource 'Object': obj_unref, obj_later_unref; a profile fact must resolve uniquely, so the rule contributes nothing; resolve: state `drop <fn>` on the resource to choose (§63, §16.2b.12)
//! expect-contract: contract: ambiguous profile match: profile gobject.v1 rules get, dispose all match 'obj_get_dispose'
//! expect-contract-not: advisory

// D51 stage 11 (ruling §7.1, §63): unique-or-nothing. Two imported
// functions fit `drop *_unref` for `Object`, so the rule contributes nothing
// — the compiler never picks — and the audit names the profile, the rule,
// the item, the candidates and the clause that resolves it. Two fn rules
// (`get`, `dispose`) both match `obj_get_dispose`: neither applies. The
// resource has no producer, so Sema has nothing to refuse; the view shows
// the resource with no destroy path and the two ambiguous rules.

use c_import("typedef struct obj obj;\nvoid obj_unref(obj *o);\nvoid obj_later_unref(obj *o);\nint obj_get_dispose(obj *o);\n")

c facade objs:
    use convention gobject.v1
    resource Object wraps *mut obj

fn main:
    print("ok")
