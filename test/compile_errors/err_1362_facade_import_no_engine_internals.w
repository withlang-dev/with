//! expect-check-fail: 'check_match' requires an explicit import (§18.1); add: use std.zl.defs.check_match

// #1362: importing a facade does not import the engine corpus under it.
// std.zlib imports std.zl.* for itself and re-exports none of it; §18.2
// ("Engine packages are ordinary explicit dependencies and are never
// ambient") leaves the zlib corpus's internals to the user's own `use`.
use std.zlib

fn main:
    check_match(0, 0, 0, 0)
