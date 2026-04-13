//! expect-stdout: ok
// Regression: `extern var` and a top-level owner `var` from different modules
// must resolve to the same global storage object during whole-program checks.

use issue113_extern_var_owner
use issue113_extern_var_ref

fn main:
    assert(issue113_read_shared() == 41)
    issue113_write_shared(42)
    assert(issue113_read_shared() == 42)
    print("ok")
