//! expect-contract: contract: resource 'Database' (test/contract/bad_no_destroy_path.w:11): producer 'db_new' (`from`/`init` at test/contract/bad_no_destroy_path.w:12) has no destroy path; resolve: state `drop <fn>` (automatic) or `destroys <fn>` on the resource (§63, §16.2b.3)
//! expect-contract-not: advisory

// D51 stage 10 (ruling §63): a producer with no valid destroy path. Sema
// refuses the facade (never half-model unsafely, §16.2b.3); the audit
// reads the same facts from Sema's snapshot and names the missing clause.

use c_import("typedef struct db db;\ndb *db_new(void);\n")

c facade dbl:
    resource Database wraps *mut db
        from db_new

fn main:
    print("ok")
