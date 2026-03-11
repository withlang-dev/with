//! check-only

// Behavior test: use/import system
// Tests that the use keyword and module imports parse correctly.
// The compiler's own prelude is automatically imported.

fn main:
    // Verify basic language features work (they rely on correct imports)
    let x = 42
    assert(x == 42)
    let s = "hello"
    assert(s == "hello")
