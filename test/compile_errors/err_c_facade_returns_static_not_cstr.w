//! expect-check-fail: fn 'note_version': 'returns static i32' — only 'returns static CStr' is ruled (§16.2b.7); a static pointer of another type stays as C declares it

// D51 stage 7 (ruling §40): static lifetime is stated for the modeled
// foreign string; nothing else is ruled to carry it.
use c_import("../behavior/c_facade_text.h")

c facade notes:
    fn note_version
        returns static i32

fn main:
    print("unreached")
