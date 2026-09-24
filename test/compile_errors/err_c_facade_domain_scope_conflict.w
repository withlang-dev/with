//! expect-check-fail: domain 'errno' is 'thread' in facade 'notes' and 'process' here; one state has one scope (§16.2b.7)

// Ruling §35-§36: two facades may declare the same domain and mean the same
// state, but one state has one scope. `notes` says errno is per thread;
// `checks` says it is process-wide — a contradiction, not a merge.

use c_import("../behavior/c_facade_text.h")

c facade notes:
    domain errno thread
    fn note_pure
        preserves domain errno

c facade checks:
    domain errno process
    fn note_fail
        lend

fn main:
    print("ok")
