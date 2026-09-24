//! expect-contract: contract: fn 'db_watch' (`retains` at test/contract/bad_retained_no_owner.w:18): the retained callback param 1: extern "C" fn(*mut c_void) -> i32 cb has no lifetime owner
//! expect-contract: `by param 2: i32 flags` receives no modeled resource; resolve: name the resource parameter that keeps it, `retains param 1 by param <resource>` (§63, §16.2b.9)
//! expect-contract-not: advisory

// D51 stage 10 (ruling §63): a retained callback with no lifetime owner —
// `retains param cb by param flags` names a plain int as the keeper, which
// receives no modeled resource, so nothing bounds the callback's life.
// (Stage 9, PR #1606, makes this a compile error; the audit reads Sema's
// snapshot either way.)

use c_import("typedef struct db db;\ndb *db_new(void);\nvoid db_close(db *d);\nint db_watch(db *d, int (*cb)(void *), int flags);\n")

c facade dbl:
    resource Database wraps *mut db
        from db_new
        drop db_close
    fn db_watch
        retains param cb by param flags

fn main:
    print("ok")
