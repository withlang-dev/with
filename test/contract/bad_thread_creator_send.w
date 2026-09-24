//! expect-contract: contract: resource 'Database' (`thread creator send drop_any_thread` at test/contract/bad_thread_creator_send.w:14): `creator` binds operations, destruction and ownership to the creating thread, which `send`/`share` contradict
//! expect-contract: resolve: state the capabilities without `creator`, or `creator` alone (§63, §16.2b.10)
//! expect-contract-not: advisory

// D51 stage 10 (ruling §63, §48-§50): an illegal thread capability
// combination — `creator` (thread-bound) together with `send`.

use c_import("typedef struct db db;\ndb *db_new(void);\nvoid db_close(db *d);\n")

c facade dbl:
    resource Database wraps *mut db
        from db_new
        drop db_close
        thread creator send drop_any_thread

fn main:
    print("ok")
