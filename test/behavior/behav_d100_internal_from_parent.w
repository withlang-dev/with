//! expect-stdout: 42

// D100 (§18.3): gadget.api lives inside lib/gadget, the parent of
// lib/gadget/internal, so it imports gadget.internal.core; this program
// reaches the value through gadget.api (err_d100_local_internal_import is
// the refusal from outside).
use gadget.api

fn main:
    print(f"{value()}")
