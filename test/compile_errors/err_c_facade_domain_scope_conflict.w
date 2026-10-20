//! expect-check-fail: domain 'notes_cache' is 'thread' in facade 'notes' and 'process' here; one state has one scope (§16.2b.7)

// Ruling §35-§36: two facades may declare the same domain and mean the same
// state, but one state has one scope. `notes` says its cache is per thread;
// `checks` says it is process-wide — a contradiction, not a merge.

use c_import("../behavior/c_facade_text.h")

c facade notes:
    domain notes_cache thread
    fn note_pure
        preserves domain notes_cache

c facade checks:
    domain notes_cache process
    fn note_fail
        lend

fn main:
    print("ok")
