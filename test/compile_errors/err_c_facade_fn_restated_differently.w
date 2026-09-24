//! expect-check-fail: fn 'note_pure' is described by two facade blocks with different clauses; one function has one contract — restate it word for word or describe it once (§16.2b)

// One function has one contract: a second block may restate it word for
// word (behav_c_facade_fn_restated), never with different clauses.

use c_import("../behavior/c_facade_text.h")

c facade notes:
    domain errno thread
    fn note_pure
        preserves domain errno

c facade notes_again:
    domain errno thread
    fn note_pure
        lend

fn main:
    print("ok")
