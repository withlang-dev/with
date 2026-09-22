//! expect-check-fail: 'is_alnum' requires an explicit import (§18.1); add: use std.string.is_alnum

// #1362: std.string's is_alnum is import-gated (§18.2); the pcre2 corpus's
// interface declaration of the same name (std.re.defs, reached through the
// prelude's std.regex) let the call compile with no import. The fix-it names
// the prelude closure's module first.
fn main:
    print(f"{is_alnum(33)}")
