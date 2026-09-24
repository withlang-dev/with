//! expect-check-fail: domain 'errno' is declared twice (§16.2b.7)

// Ruling §35 merges a domain two facades declare; one facade declaring it
// twice is a duplicate, not a merge.

use c_import("../behavior/c_facade_text.h")

c facade notes:
    domain errno thread
    domain errno thread
    fn note_pure
        preserves domain errno

fn main:
    print("ok")
