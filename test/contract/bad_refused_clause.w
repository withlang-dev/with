//! expect-contract: audit:contract: compilation failed (see the diagnostics above); the view is a snapshot of the partial semantics, not a verdict
//! expect-contract-not: advisory

// D51 stage 10 (ruling §63) over a stage 9 refusal: `retains param cb by
// param flags` names a plain int as the keeper, which Sema rejects at the
// clause (§16.2b.9; pinned as a compile error in
// test/compile_errors/err_c_facade_retains_by_non_resource.w). The contract
// audit still runs over Sema's snapshot, but a program the compiler refused
// is never an `ok` audit — a tool that stayed silent over an error is a
// bug (the harness caught exactly that when #1606 landed under stage 10).

use c_import("typedef struct db db;\ndb *db_new(void);\nvoid db_close(db *d);\nint db_watch(db *d, int (*cb)(void *), int flags);\n")

c facade dbl:
    resource Database wraps *mut db
        from db_new
        drop db_close
    fn db_watch
        retains param cb by param flags

fn main:
    print("ok")
