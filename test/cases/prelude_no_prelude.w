//! expect-error: undefined variable
//! args: --no-prelude

// Test: --no-prelude removes ambient prelude names.
// println should not be available without the prelude.

fn main:
    println("should fail")
