//! expect-stdout: ok
// #2335: an `extern var` naming another module's typed owner global resolves
// as one with an untyped owner does (#113). The frontend dropped an
// `extern var` whose name, mutability and type text matched the owner's
// declaration; that took the declaring module's grant with it, and the
// owner's global, private to its own package (D100), read as not visible.
// Sema merges an `extern var` with its owner, so the user tiers keep it.

use issue2335_extern_var_typed_owner
use issue2335_extern_var_typed_ref

fn main:
    assert(issue2335_read_shared() == 41)
    issue2335_write_shared(42)
    assert(issue2335_read_shared() == 42)
    print("ok")
