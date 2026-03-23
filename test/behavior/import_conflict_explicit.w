//! expect-stdout: ok

// Test: existing explicit-import conflict behavior remains unchanged.
// When two explicit `use` imports both define the same function,
// the later import wins (later-wins semantics).
// shadow_helper defines map(x) -> x * 10
// shadow_helper2 defines map(x) -> x * 100
// shadow_helper2 comes later so its map should win.

use shadow_helper
use shadow_helper2

fn main:
    assert(map(5) == 500)
    println("ok")
