//! expect-stdout: ok

// Test: explicit use import shadows prelude-provided functions.
// The prelude imports std.iter which provides map(Vec[str], fn(str)->i32).
// An explicit `use shadow_helper` that also defines map must shadow
// the prelude's map.

use shadow_helper

fn main:
    assert(map(5) == 50)
    print("ok")
