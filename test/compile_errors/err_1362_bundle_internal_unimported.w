//! expect-check-fail: 'u128_mul_would_overflow' requires an explicit import (§18.1); add: use std.engines.pcre2.defs.u128_mul_would_overflow

// #1362: a bundle corpus's internals are not the prelude (§18.2). The
// prelude's std.regex imports the pcre2 corpus (std.engines.pcre2.*) for itself; that
// edge used to make every pub name of std.engines.pcre2.defs callable from any program
// with no import. It needs a `use`, and the diagnostic names it.
fn main:
    print(f"{u128_mul_would_overflow(1, 2)}")
