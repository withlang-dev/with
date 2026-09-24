//! expect-contract: contract: advisory: sqlite3_close_v2 (test/contract/bad_advisory_close.w:19) is exposed as a borrow of Database
//! expect-contract: = heuristic: name segment `close` and a signature taking Database's representation resemble a destroying operation
//! expect-contract: = help: declare `destroys` if it destroys the resource, or explicitly declare `lend` to confirm borrowing semantics (§63)
//! expect-contract-not: sqlite3_release_memory
//! expect-contract: advisories=1

// D51 stage 10 (ruling §63): `sqlite3_close_v2` is described with nothing
// stronger than the described-fn lend, and its name and shape resemble a
// destroyer of Database — the advisory names it and changes nothing.
// `sqlite3_release_memory` has the same shape but an explicit `lend`: the
// author's review is recorded and the advisory is silent.

use c_import("typedef struct sqlite3 sqlite3;\nsqlite3 *sqlite3_new(void);\nint sqlite3_close(sqlite3 *db);\nint sqlite3_close_v2(sqlite3 *db);\nint sqlite3_release_memory(sqlite3 *db);\n")

c facade sqlite:
    resource Database wraps *mut sqlite3
        from sqlite3_new
        drop sqlite3_close
    fn sqlite3_close_v2
        of Database
    fn sqlite3_release_memory
        lend

fn main:
    print("ok")
